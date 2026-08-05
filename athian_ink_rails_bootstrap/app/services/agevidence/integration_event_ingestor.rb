require "json"
require "time"

module Agevidence
  class IntegrationEventIngestor
    Result = Data.define(:event, :duplicate)

    def initialize(developer_account:, raw_body:)
      @developer_account = developer_account
      @raw_body = raw_body
    end

    def call
      envelope = JSON.parse(raw_body)
      validate_envelope!(envelope)
      source = IntegrationSource.active.find_by!(
        developer_account: developer_account,
        key: envelope.fetch("source")
      )
      verification = IntegrationSignatureVerifier.new(source: source, envelope: envelope).verify!
      subject = envelope.fetch("subject")
      integrity = envelope.fetch("integrity")
      duplicate = false

      event = IntegrationEvent.transaction do
        existing = source.integration_events.lock.find_by(external_event_id: envelope.fetch("event_id"))
        if existing
          unless existing.payload_digest == verification.fetch(:payload_digest)
            raise ArgumentError, "event_id already exists with a different payload digest"
          end
          duplicate = true
          existing
        else
          source.integration_events.create!(
            external_event_id: envelope.fetch("event_id"),
            event_type: envelope.fetch("event_type"),
            schema_version: envelope.fetch("schema_version"),
            external_object_type: subject.fetch("type"),
            external_object_id: subject.fetch("external_id"),
            occurred_at: Time.iso8601(envelope.fetch("occurred_at")),
            received_at: Time.current,
            raw_envelope: raw_body,
            payload: envelope,
            correlation: envelope.fetch("correlation", {}),
            payload_digest: verification.fetch(:payload_digest),
            signature: integrity.fetch("signature"),
            processing_status: "accepted"
          ).tap do
            source.update!(last_event_at: Time.current)
          end
        end
      end

      ProcessIntegrationEventJob.perform_later(event.id) unless duplicate
      Result.new(event: event, duplicate: duplicate)
    rescue JSON::ParserError => e
      raise ArgumentError, "invalid JSON: #{e.message}"
    end

    private

    attr_reader :developer_account, :raw_body

    def validate_envelope!(envelope)
      %w[event_id event_type schema_version source occurred_at subject data integrity].each do |field|
        raise ArgumentError, "missing #{field}" if envelope[field].blank?
      end

      unless IntegrationEvent::EVENT_TYPES.include?(envelope["event_type"])
        raise ArgumentError, "unsupported event_type: #{envelope['event_type']}"
      end

      subject = envelope["subject"]
      raise ArgumentError, "subject must be an object" unless subject.is_a?(Hash)
      raise ArgumentError, "missing subject.type" if subject["type"].blank?
      raise ArgumentError, "missing subject.external_id" if subject["external_id"].blank?

      integrity = envelope["integrity"]
      raise ArgumentError, "integrity must be an object" unless integrity.is_a?(Hash)
      raise ArgumentError, "missing integrity.payload_digest" if integrity["payload_digest"].blank?
      raise ArgumentError, "missing integrity.signature" if integrity["signature"].blank?

      Time.iso8601(envelope.fetch("occurred_at"))
    rescue KeyError => e
      raise ArgumentError, e.message
    end
  end
end
