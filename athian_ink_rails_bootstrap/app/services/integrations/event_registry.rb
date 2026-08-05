module Integrations
  class EventRegistry
    SUPPORTED_SCHEMA_VERSION = "1.0.0"

    EVENT_TYPES = {
      "project.registered" => {
        handler: "Integrations::EventHandlers::ProjectRegisteredHandler",
        subject_type: "project",
        required_data: %w[project_id project_name producer_id country_code monitoring_period_start monitoring_period_end current_status]
      },
      "protocol.version_assigned" => {
        handler: "Integrations::EventHandlers::ProtocolVersionAssignedHandler",
        subject_type: "protocol_version",
        required_data: %w[project_id protocol_id protocol_version_id version effective_from country_code status]
      },
      "source.manifest_available" => {
        handler: "Integrations::EventHandlers::SourceManifestAvailableHandler",
        subject_type: "source_manifest",
        required_data: %w[manifest_id project_id source_systems objects retention_policy access_references data_classification]
      },
      "intervention.recorded" => {
        handler: "Integrations::EventHandlers::InterventionRecordedHandler",
        subject_type: "intervention",
        required_data: %w[intervention_id project_id product_id animal_or_herd_reference delivery_or_administration_date dose_or_quantity unit source_manifest_id]
      },
      "model.run_completed" => {
        handler: "Integrations::EventHandlers::ModelRunCompletedHandler",
        subject_type: "model_run",
        required_data: %w[model_run_id project_id model_identifier model_version weight_digest adapter_identifier runtime_configuration input_manifest_digest output_digest limitations status]
      },
      "verification.status_changed" => {
        handler: "Integrations::EventHandlers::VerificationStatusChangedHandler",
        subject_type: "verification_engagement",
        required_data: %w[verification_engagement_id project_id verifier_id scope criteria criteria_version status exceptions effective_at]
      },
      "asset.status_changed" => {
        handler: "Integrations::EventHandlers::AssetStatusChangedHandler",
        subject_type: "asset",
        required_data: %w[asset_id project_id asset_type quantity unit vintage status]
      },
      "producer.payment_recorded" => {
        handler: "Integrations::EventHandlers::ProducerPaymentRecordedHandler",
        subject_type: "producer_payment",
        required_data: %w[payment_id producer_id project_id gross_amount producer_amount currency payment_date payment_status calculation_basis transaction_reference]
      }
    }.freeze

    RESULT_EVENT_TYPES = %w[
      artifact.ready
      artifact.verification_failed
      reliance.recorded
    ].freeze

    class ValidationResult
      attr_reader :status, :code, :message

      def initialize(status:, code: nil, message: nil)
        @status = status
        @code = code
        @message = message
      end

      def valid?
        status == :valid
      end

      def unknown?
        status == :unknown
      end
    end

    class << self
      def known?(event_type)
        EVENT_TYPES.key?(event_type)
      end

      def handler_for(event_type)
        EVENT_TYPES.fetch(event_type).fetch(:handler).constantize
      end

      def validate_envelope(payload)
        missing = %w[event_id event_type schema_version source occurred_at subject data integrity].select do |key|
          payload[key].blank?
        end
        return invalid(:envelope_invalid, "Missing envelope field(s): #{missing.join(', ')}") if missing.any?
        return invalid(:event_id_missing, "event_id is required.") if payload["event_id"].blank?
        return invalid(:schema_version, "Unsupported schema version.") unless payload["schema_version"] == SUPPORTED_SCHEMA_VERSION

        subject = payload["subject"]
        return invalid(:envelope_invalid, "subject.type and subject.external_id are required.") unless subject.is_a?(Hash) && subject["type"].present? && subject["external_id"].present?

        integrity = payload["integrity"]
        return invalid(:envelope_invalid, "integrity payload fields are required.") unless integrity.is_a?(Hash) && integrity["payload_digest"].present? && integrity["signature_algorithm"].present? && integrity["signature"].present?

        Time.zone.parse(payload["occurred_at"].to_s)
        ValidationResult.new(status: :valid)
      rescue ArgumentError
        invalid(:envelope_invalid, "occurred_at must be a timestamp.")
      end

      def validate_event(payload)
        event_type = payload["event_type"].to_s
        return ValidationResult.new(status: :unknown, code: ErrorCatalog::CODES[:unknown_event_type], message: ErrorCatalog.message(ErrorCatalog::CODES[:unknown_event_type])) unless known?(event_type)

        data = payload["data"]
        return invalid(:event_invalid, "data must be an object.") unless data.is_a?(Hash)

        missing = EVENT_TYPES.fetch(event_type).fetch(:required_data).select { |key| data[key].blank? }
        return invalid(:event_invalid, "Missing event data field(s): #{missing.join(', ')}") if missing.any?

        subject_type = EVENT_TYPES.fetch(event_type).fetch(:subject_type)
        subject = payload.fetch("subject", {})
        return invalid(:event_invalid, "subject.type must be #{subject_type}.") if subject["type"] != subject_type

        ValidationResult.new(status: :valid)
      end

      private

      def invalid(code_key, message)
        code = ErrorCatalog::CODES.fetch(code_key)
        ValidationResult.new(status: :invalid, code: code, message: message.presence || ErrorCatalog.message(code))
      end
    end
  end
end
