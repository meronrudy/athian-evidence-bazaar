module Integrations
  class IngestEvent
    MAX_BYTES = 1.megabyte

    Result = Struct.new(
      :accepted,
      :duplicate,
      :integration_event,
      :operation,
      :error_code,
      :error_message,
      keyword_init: true
    ) do
      def error?
        error_code.present?
      end
    end

    def self.call(integration_source:, raw_body:, headers:)
      new(integration_source: integration_source, raw_body: raw_body, headers: headers).call
    end

    def initialize(integration_source:, raw_body:, headers:)
      @integration_source = integration_source
      @raw_body = raw_body.to_s
      @headers = headers
    end

    def call
      return error(:source_unknown) unless integration_source
      return error(:source_suspended) unless integration_source.active_for_ingestion?
      return error(:event_too_large) if raw_body.bytesize > MAX_BYTES

      payload = parse_payload
      return payload if payload.is_a?(Result)

      return error(:event_id_missing) if payload["event_id"].blank?
      return error(:source_unknown, "Envelope source does not match the integration credential.") unless payload["source"] == integration_source.key

      commitments = CanonicalizeEvent.call(payload)
      provided_digest = payload.dig("integrity", "payload_digest").to_s
      duplicate = find_duplicate(payload.fetch("event_id"))
      return duplicate_result(duplicate, commitments.fetch(:payload_digest)) if duplicate
      if EventRegistry.known?(payload["event_type"]) && !integration_source.allows_event_type?(payload["event_type"])
        return persist_invalid(payload, commitments, :event_invalid, "Event type is not enabled for this integration source.")
      end
      return persist_invalid(payload, commitments, :digest_mismatch) unless provided_digest == commitments.fetch(:payload_digest)

      signature_result = verify_signature(payload, commitments.fetch(:canonical_payload))
      return persist_invalid(payload, commitments, :signature_unsupported, signature_result.fetch(:message)) if signature_result.fetch(:status) == "unsupported"
      return persist_invalid(payload, commitments, :signature_invalid, signature_result.fetch(:message)) unless signature_result.fetch(:status) == "valid"

      envelope_result = EventRegistry.validate_envelope(payload)
      return persist_invalid(payload, commitments, :envelope_invalid, envelope_result.message) unless envelope_result.valid?

      event_result = EventRegistry.validate_event(payload)
      return persist_unknown(payload, commitments) if event_result.unknown?
      return persist_invalid(payload, commitments, :event_invalid, event_result.message) unless event_result.valid?

      persist_accepted(payload, commitments)
    rescue StandardError => e
      Result.new(accepted: false, duplicate: false, error_code: ErrorCatalog::CODES[:internal_error], error_message: e.message)
    end

    private

    attr_reader :integration_source, :raw_body, :headers

    def parse_payload
      JSON.parse(raw_body)
    rescue JSON::ParserError
      error(:invalid_json)
    end

    def find_duplicate(event_id)
      integration_source.integration_events.find_by(external_event_id: event_id)
    end

    def duplicate_result(event, incoming_digest)
      return conflict(event) unless event.payload_digest == incoming_digest

      Result.new(
        accepted: true,
        duplicate: true,
        integration_event: event,
        operation: event.primary_operation,
        error_code: nil,
        error_message: nil
      )
    end

    def conflict(event)
      Result.new(
        accepted: false,
        duplicate: true,
        integration_event: event,
        error_code: ErrorCatalog::CODES[:event_id_conflict],
        error_message: ErrorCatalog.message(ErrorCatalog::CODES[:event_id_conflict])
      )
    end

    def verify_signature(payload, canonical_payload)
      timestamp = header("X-Athian-Timestamp").presence || payload["occurred_at"]
      InkReceipts.verify_integration_signature(
        algorithm: integration_source.signature_algorithm,
        secret: integration_source.verification_secret,
        public_key: integration_source.verification_public_key,
        timestamp: timestamp,
        canonical_payload: canonical_payload,
        signature: header("X-Athian-Signature").presence || payload.dig("integrity", "signature")
      )
    end

    def persist_accepted(payload, commitments)
      event = nil
      operation = nil
      ActiveRecord::Base.transaction do
        event = create_event!(
          payload: payload,
          commitments: commitments,
          signature_status: "valid",
          schema_status: "valid",
          processing_status: "accepted"
        )
        operation = event.integration_operations.create!(
          operation_type: "event_processing",
          status: "pending",
          idempotency_key: "integration-event:#{integration_source.key}:#{event.external_event_id}"
        )
        event.update!(operation_external_id: operation.external_id)
      end
      Integrations::ProcessEventJob.perform_later(event.id)
      Result.new(accepted: true, duplicate: false, integration_event: event, operation: operation)
    end

    def persist_unknown(payload, commitments)
      event = create_event!(
        payload: payload,
        commitments: commitments,
        signature_status: "valid",
        schema_status: "unknown_event_type",
        processing_status: "ignored_unknown_type",
        error_code: ErrorCatalog::CODES[:unknown_event_type],
        error_message: ErrorCatalog.message(ErrorCatalog::CODES[:unknown_event_type])
      )
      operation = event.integration_operations.create!(
        operation_type: "event_processing",
        status: "succeeded",
        idempotency_key: "integration-event:#{integration_source.key}:#{event.external_event_id}",
        completed_at: Time.current,
        result_json: { ignored: true, reason: "unknown_event_type" }
      )
      event.update!(operation_external_id: operation.external_id)
      Result.new(accepted: true, duplicate: false, integration_event: event, operation: operation)
    end

    def persist_invalid(payload, commitments, code_key, message = nil)
      code = ErrorCatalog::CODES.fetch(code_key)
      event = nil
      ActiveRecord::Base.transaction do
        event = create_event!(
          payload: payload,
          commitments: commitments,
          signature_status: code_key == :signature_unsupported ? "unsupported" : (code_key == :signature_invalid ? "invalid" : "unchecked"),
          schema_status: %i[envelope_invalid event_invalid].include?(code_key) ? "invalid" : "unchecked",
          processing_status: code_key == :signature_invalid ? "signature_invalid" : "schema_invalid",
          error_code: code,
          error_message: message.presence || ErrorCatalog.message(code)
        )
      end
      Result.new(accepted: false, duplicate: false, integration_event: event, error_code: code, error_message: message.presence || ErrorCatalog.message(code))
    rescue ActiveRecord::RecordNotUnique
      duplicate = find_duplicate(payload["event_id"])
      duplicate_result(duplicate, commitments.fetch(:payload_digest))
    end

    def create_event!(payload:, commitments:, signature_status:, schema_status:, processing_status:, error_code: nil, error_message: nil)
      subject = payload.fetch("subject", {})
      integration_source.integration_events.create!(
        external_event_id: payload.fetch("event_id"),
        event_type: payload.fetch("event_type", "unknown"),
        schema_version: payload.fetch("schema_version", "unknown"),
        external_object_type: subject["type"],
        external_object_id: subject["external_id"],
        occurred_at: parse_time(payload["occurred_at"]),
        received_at: Time.current,
        raw_payload_json: raw_body,
        canonical_payload_json: commitments.fetch(:canonical_payload),
        payload_digest: commitments.fetch(:payload_digest),
        provided_digest: payload.dig("integrity", "payload_digest"),
        signature: payload.dig("integrity", "signature"),
        signature_algorithm: payload.dig("integrity", "signature_algorithm"),
        signature_status: signature_status,
        schema_status: schema_status,
        processing_status: processing_status,
        processing_error_code: error_code,
        processing_error_message: error_message,
        supersedes_event_id: payload["supersedes_event_id"],
        correlation_json: payload.fetch("correlation", {})
      ).tap do |event|
        integration_source.update!(last_event_at: event.received_at)
      end
    end

    def parse_time(value)
      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def error(code_key, message = nil)
      code = ErrorCatalog::CODES.fetch(code_key)
      Result.new(
        accepted: false,
        duplicate: false,
        error_code: code,
        error_message: message.presence || ErrorCatalog.message(code)
      )
    end

    def header(name)
      headers.respond_to?(:[]) ? headers[name].to_s : nil
    end
  end
end
