module Integrations
  module EventHandlers
    class BaseHandler
      def initialize(event:)
        @event = event
        @projections = []
        @receipt_requests = []
        @warnings = []
        @external_mappings = []
      end

      def call
        raise NotImplementedError
      end

      private

      attr_reader :event, :projections, :receipt_requests, :warnings, :external_mappings

      def result
        HandlerResult.new(
          projections: projections,
          receipt_requests: receipt_requests,
          warnings: warnings,
          external_mappings: external_mappings
        )
      end

      def data
        event.data
      end

      def correlation
        event.correlation
      end

      def project_external_id
        data["project_id"].presence || correlation["project_id"]
      end

      def developer_project
        return @developer_project if defined?(@developer_project)

        mapping = mapping_for("project", project_external_id, "Agevidence::DeveloperProject") if project_external_id.present?
        @developer_project = mapping&.internal_record
      end

      def append_projection!(projection_type:, external_subject_id:, current_state:, data_json:, external_project_id: project_external_id)
        projection = EvidenceProjection.where(
          source_event: event,
          projection_type: projection_type,
          external_subject_id: external_subject_id
        ).first
        return projection if projection

        prior = EvidenceProjection.where(
          projection_type: projection_type,
          external_project_id: external_project_id,
          external_subject_id: external_subject_id
        ).order(projection_version: :desc).first
        projection = EvidenceProjection.create!(
          projection_type: projection_type,
          external_project_id: external_project_id,
          external_subject_type: event.external_object_type,
          external_subject_id: external_subject_id,
          current_state: current_state,
          source_event: event,
          source_event_digest: event.payload_digest,
          projection_version: prior ? prior.projection_version + 1 : 1,
          data_json: data_json,
          occurred_at: event.occurred_at,
          projected_at: Time.current,
          supersedes_projection: prior
        )
        projections << projection
        projection
      end

      def map_external!(external_object_type:, external_object_id:, record:, external_version: nil, metadata: {})
        mapping = ExternalObjectMapping.find_or_initialize_by(
          integration_source: event.integration_source,
          external_object_type: external_object_type,
          external_object_id: external_object_id,
          internal_record_type: record.class.name
        )
        mapping.internal_record_id ||= record.id
        mapping.external_version = external_version if external_version.present?
        mapping.last_integration_event = event
        mapping.first_seen_at ||= Time.current
        mapping.last_seen_at = Time.current
        mapping.metadata_json = mapping.metadata_json.merge(metadata)
        mapping.save!
        external_mappings << mapping unless external_mappings.include?(mapping)
        mapping
      end

      def mapping_for(external_object_type, external_object_id, internal_record_type)
        return nil if external_object_id.blank?

        ExternalObjectMapping.find_by(
          integration_source: event.integration_source,
          external_object_type: external_object_type,
          external_object_id: external_object_id,
          internal_record_type: internal_record_type
        )
      end

      def receipt_request!(aggregate:, receipt_type:, schema_id:, payload:)
        canonical_payload = payload.deep_stringify_keys
        canonical = InkReceipts.canonicalize_integration_event(canonical_payload)
        payload_digest = InkReceipts.integration_payload_digest(canonical)
        idempotency_key = [
          event.integration_source.key,
          event.external_event_id,
          receipt_type,
          event.payload_digest
        ].join(":")

        outbox = ReceiptOutbox.find_or_create_by!(idempotency_key: idempotency_key) do |record|
          record.integration_event = event
          record.aggregate_type = aggregate.class.name
          record.aggregate_id = aggregate.id
          record.receipt_type = receipt_type
          record.schema_id = schema_id
          record.schema_version = event.schema_version
          record.canonical_payload_json = canonical_payload
          record.payload_digest = payload_digest
          record.status = "pending"
        end
        receipt_requests << outbox unless receipt_requests.include?(outbox)
        outbox
      end

      def ensure_lightweight_avsa!(project)
        return project.avsa if project.avsa

        protocol = project.protocol || Protocol.find_or_create_by!(code: "ATH-INTEGRATION") do |record|
          record.name = "Athian Integration Projection Protocol"
          record.version = "v1"
          record.governance_version = "ATH-INTEGRATION-2026.1"
          record.status = "active"
          record.description = "Lightweight protocol projection used only to anchor event-derived receipt projections."
        end

        avsa = Avsa.create!(
          protocol: protocol,
          external_id: "AVSA-INTEGRATION-#{project.id}",
          title: project.name,
          producer_name: project.developer_account.name,
          status: "in_progress",
          verified_quantity: 0,
          unit: "tCO2e",
          reporting_period: data["monitoring_period_start"].present? ? "#{data['monitoring_period_start']} to #{data['monitoring_period_end']}" : nil,
          local_verification_status: "indeterminate",
          methodology_name: protocol.name,
          methodology_version: protocol.version
        )
        project.update!(avsa: avsa, protocol: protocol)
        map_external!(external_object_type: "avsa", external_object_id: avsa.external_id, record: avsa)
        avsa
      end

      def state_for_parent(project)
        project ? "complete" : "pending_parent"
      end
    end
  end
end
