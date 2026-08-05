module Agevidence
  class SourceRecordProjection
    def initialize(source_record:)
      @source_record = source_record
      @project = source_record.developer_project
    end

    def call
      ensure_project_mapping!
      event = build_source_manifest_event!
      source_record.update!(source_event: event, status: "projected")
      Integrations::ProcessEventJob.perform_later(event.id)
      event
    end

    private

    attr_reader :source_record, :project

    def build_source_manifest_event!
      source = integration_source
      payload = event_payload(source)
      canonical = InkReceipts.canonicalize_integration_event(payload)
      payload["integrity"]["payload_digest"] = InkReceipts.integration_payload_digest(canonical)
      payload["integrity"]["signature"] = InkReceipts.sign_integration_payload(
        secret: source.verification_secret,
        timestamp: payload.fetch("occurred_at"),
        canonical_payload: canonical
      )
      canonical = InkReceipts.canonicalize_integration_event(payload)

      event = nil
      ActiveRecord::Base.transaction do
        event = source.integration_events.find_or_create_by!(external_event_id: payload.fetch("event_id")) do |record|
          record.event_type = payload.fetch("event_type")
          record.schema_version = payload.fetch("schema_version")
          record.external_object_type = payload.dig("subject", "type")
          record.external_object_id = payload.dig("subject", "external_id")
          record.occurred_at = Time.zone.parse(payload.fetch("occurred_at"))
          record.received_at = Time.current
          record.raw_payload_json = JSON.generate(payload)
          record.canonical_payload_json = canonical
          record.payload_digest = payload.dig("integrity", "payload_digest")
          record.provided_digest = payload.dig("integrity", "payload_digest")
          record.signature = payload.dig("integrity", "signature")
          record.signature_algorithm = payload.dig("integrity", "signature_algorithm")
          record.signature_status = "valid"
          record.schema_status = "valid"
          record.processing_status = "accepted"
          record.correlation_json = payload.fetch("correlation")
        end
        event.integration_operations.find_or_create_by!(idempotency_key: "developer-os-source-record:#{source_record.id}") do |operation|
          operation.operation_type = "source_record_projection"
          operation.status = "pending"
        end
        event.update!(operation_external_id: event.current_operation.external_id)
      end
      event
    end

    def event_payload(source)
      now = Time.current.iso8601
      {
        "event_id" => "evt_source_record_#{source_record.id}",
        "event_type" => "source.manifest_available",
        "schema_version" => "1.0.0",
        "source" => source.key,
        "occurred_at" => now,
        "subject" => {
          "type" => "source_manifest",
          "external_id" => "source-record-manifest-#{source_record.id}"
        },
        "correlation" => {
          "project_id" => external_project_id
        },
        "data" => {
          "manifest_id" => "source-record-manifest-#{source_record.id}",
          "project_id" => external_project_id,
          "source_systems" => [source_record.source_system.presence || "developer_source_console"],
          "objects" => [
            {
              "document_id" => source_record.document_id,
              "controlled_uri" => source_record.controlled_uri,
              "commitment" => source_record.commitment,
              "evidence_type" => source_record.evidence_type
            }
          ],
          "object_digests" => [source_record.commitment],
          "retention_policy" => source_record.metadata_json["retention_policy"].presence || "controlled_7_year",
          "access_references" => [source_record.controlled_uri],
          "data_classification" => source_record.disclosure_status
        },
        "integrity" => {
          "payload_digest" => "pending",
          "signature_algorithm" => "hmac-sha256",
          "signature" => "pending"
        }
      }
    end

    def ensure_project_mapping!
      ExternalObjectMapping.find_or_create_by!(
        integration_source: integration_source,
        external_object_type: "project",
        external_object_id: external_project_id,
        internal_record_type: "Agevidence::DeveloperProject"
      ) do |mapping|
        mapping.internal_record_id = project.id
        mapping.first_seen_at = Time.current
        mapping.last_seen_at = Time.current
        mapping.metadata_json = { origin: "developer_os_source_records" }
      end
    end

    def external_project_id
      "developer-project-#{project.id}"
    end

    def integration_source
      @integration_source ||= IntegrationSource.find_or_create_by!(key: "agevidence_developer_os") do |source|
        source.name = "AgEvidence Developer OS"
        source.environment = Rails.env
        source.status = "active"
        source.signature_algorithm = "hmac_sha256"
        source.verification_secret_ciphertext = "developer-os-internal-secret"
        source.allowed_event_types = ["source.manifest_available"]
        source.metadata_json = {
          authority_boundary: "Internal source-record console event; not an upstream operational authority."
        }
      end
    end
  end
end
