module Agevidence
  class IntegrationEventProcessor
    RECEIPT_DEFINITIONS = {
      "project.registered" => ["project_registration_receipt", "athian.integration.project_registration.v1"],
      "protocol.version_assigned" => ["protocol_assignment_receipt", "athian.integration.protocol_assignment.v1"],
      "source.manifest_available" => ["source_manifest_receipt", "athian.integration.source_manifest.v1"],
      "intervention.recorded" => ["intervention_receipt", "athian.integration.intervention.v1"],
      "model.run_completed" => ["model_execution_receipt", "athian.agevidence.model_execution.v1"],
      "verification.status_changed" => ["verifier_receipt", "athian.integration.verification_status.v1"],
      "asset.status_changed" => ["asset_status_receipt", "athian.integration.asset_status.v1"],
      "producer.payment_recorded" => ["producer_payment_receipt", "athian.integration.producer_payment.v1"]
    }.freeze

    def initialize(event)
      @event = event
    end

    def call
      outbox = nil

      event.with_lock do
        return event if event.processing_status == "processed"

        event.update!(
          processing_status: "processing",
          processing_error: nil,
          attempt_count: event.attempt_count + 1,
          last_attempt_at: Time.current
        )

        mapping = upsert_mapping!
        internal_record = project_event? ? project_projection!(mapping) : event_projection!(mapping)
        mapping.update!(
          internal_record: internal_record || mapping.internal_record,
          external_version: event.schema_version,
          last_integration_event: event,
          projection_payload: normalized_projection
        )

        project = resolve_project(mapping, internal_record)
        update_project_stage!(project)
        outbox = create_receipt_outbox!(project)
        event.update!(processing_status: "processed", processed_at: Time.current)
      end

      DispatchReceiptOutboxJob.perform_later(outbox.id) if outbox
      event
    rescue StandardError => e
      mark_failed!(e)
      raise
    end

    private

    attr_reader :event

    def project_event?
      event.event_type == "project.registered"
    end

    def upsert_mapping!
      event.integration_source.external_object_mappings.find_or_initialize_by(
        external_object_type: event.external_object_type,
        external_object_id: event.external_object_id
      )
    end

    def project_projection!(mapping)
      return mapping.internal_record if mapping.internal_record.is_a?(DeveloperProject)

      data = event.payload.fetch("data", {})
      project_type = data["project_type"].to_s
      project_type = "intervention" unless DeveloperProject::PROJECT_TYPES.include?(project_type)

      event.integration_source.developer_account.developer_projects.create!(
        name: data["name"].presence || data["project_name"].presence || event.external_object_id,
        project_type: project_type,
        commercialization_stage: data["commercialization_stage"],
        target_claim: data["target_claim"],
        protocol_status: "mapping",
        integration_status: "not_started"
      )
    end

    def event_projection!(mapping)
      return model_run_projection!(mapping) if event.event_type == "model.run_completed"

      mapping.internal_record
    end

    def model_run_projection!(mapping)
      return mapping.internal_record if mapping.internal_record.is_a?(ModelRun)

      project = resolve_project(mapping, nil)
      return unless project

      data = event.payload.fetch("data", {})
      adapter_id = data["adapter_id"].presence || data["model_id"].presence || "external-model"
      adapter = ModelAdapter.find_or_create_by!(adapter_id: adapter_id) do |record|
        record.base_model_id = data["base_model_id"].presence || data["model_id"].presence || adapter_id
        record.provider = data["provider"]
        record.license = data["license"].presence || "externally declared"
        record.runtime = data["runtime"].presence || "external"
        record.weights_digest = data["weights_digest"]
        record.adapter_digest = data["adapter_digest"]
        record.status = "active"
      end

      project.model_runs.create!(
        model_adapter: adapter,
        task: data["task"].presence || "external_model_run",
        status: "completed",
        prompt_digest: data["prompt_digest"],
        retrieval_digest: data["retrieval_digest"],
        input_manifest: data["inputs"].is_a?(Hash) ? data["inputs"] : { "inputs" => data["inputs"] },
        normalized_output: data["outputs"].is_a?(Hash) ? data["outputs"] : { "outputs" => data["outputs"], "limitations" => Array(data["limitations"]) },
        output_digest: data["output_digest"],
        runtime_metadata: data.slice("runtime", "model_id", "adapter_id", "provider"),
        started_at: parse_optional_time(data["started_at"]),
        completed_at: parse_optional_time(data["completed_at"]) || event.occurred_at
      )
    end

    def resolve_project(mapping, internal_record)
      return internal_record if internal_record.is_a?(DeveloperProject)
      return internal_record.developer_project if internal_record.respond_to?(:developer_project)
      return mapping.internal_record if mapping.internal_record.is_a?(DeveloperProject)

      external_project_id = event.correlation["project_id"] || event.payload.dig("data", "project_id")
      return if external_project_id.blank?

      event.integration_source.external_object_mappings
           .where(external_object_id: external_project_id, internal_record_type: "Agevidence::DeveloperProject")
           .first&.internal_record
    end

    def update_project_stage!(project)
      return unless project

      status = case event.event_type
               when "source.manifest_available", "intervention.recorded" then "source_registered"
               when "model.run_completed" then "model_ready"
               when "verification.status_changed" then "receipt_ready"
               when "asset.status_changed", "producer.payment_recorded" then "artifact_ready"
               end
      project.update!(integration_status: status) if status
    end

    def create_receipt_outbox!(project)
      receipt_type, schema_id = RECEIPT_DEFINITIONS.fetch(event.event_type)
      aggregate_id = event.correlation["project_id"].presence || project_external_id(project) || event.external_object_id
      idempotency_key = "#{event.integration_source.key}:#{event.external_event_id}:#{receipt_type}"
      previous_digests = ReceiptOutbox.joins(:integration_event)
                                      .where(aggregate_id: aggregate_id, status: "processed")
                                      .where(agevidence_integration_events: { integration_source_id: event.integration_source_id })
                                      .order(:created_at)
                                      .pluck(:payload_digest)
                                      .compact
                                      .last(8)

      ReceiptOutbox.find_or_create_by!(idempotency_key: idempotency_key) do |record|
        record.integration_event = event
        record.aggregate_type = "external_project"
        record.aggregate_id = aggregate_id
        record.receipt_type = receipt_type
        record.schema_id = schema_id
        record.canonical_payload = normalized_projection.merge(
          "parent_receipt_digests" => previous_digests,
          "internal_project_id" => project&.id
        )
        record.status = "pending"
      end
    end

    def normalized_projection
      {
        "event_id" => event.external_event_id,
        "event_type" => event.event_type,
        "schema_version" => event.schema_version,
        "source" => event.integration_source.key,
        "occurred_at" => event.occurred_at.iso8601,
        "subject" => {
          "type" => event.external_object_type,
          "external_id" => event.external_object_id
        },
        "correlation" => event.correlation,
        "data" => event.payload.fetch("data", {}),
        "upstream_payload_digest" => event.payload_digest
      }
    end

    def project_external_id(project)
      return unless project

      event.integration_source.external_object_mappings
           .find_by(internal_record: project)&.external_object_id
    end

    def parse_optional_time(value)
      Time.iso8601(value) if value.present?
    rescue ArgumentError
      nil
    end

    def mark_failed!(error)
      attempts = [event.attempt_count, 1].max
      event.update_columns(
        processing_status: attempts >= 5 ? "dead_letter" : "failed",
        processing_error: "#{error.class}: #{error.message}".truncate(4_000),
        last_attempt_at: Time.current,
        updated_at: Time.current
      )
    rescue StandardError
      nil
    end
  end
end
