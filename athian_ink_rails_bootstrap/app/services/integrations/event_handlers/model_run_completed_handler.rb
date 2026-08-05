module Integrations
  module EventHandlers
    class ModelRunCompletedHandler < BaseHandler
      def call
        project = developer_project
        projection = append_projection!(
          projection_type: "model_run",
          external_subject_id: data.fetch("model_run_id"),
          current_state: state_for_parent(project),
          data_json: data.merge(authority_boundary: "model output remains candidate evidence")
        )

        if project
          adapter = Agevidence::ModelAdapter.find_or_create_by!(adapter_id: data.fetch("adapter_identifier")) do |record|
            record.base_model_id = data.fetch("model_identifier")
            record.provider = data["model_provider"]
            record.license = data["model_license"].presence || "upstream_declared"
            record.runtime = data.dig("runtime_configuration", "runtime").presence || "upstream"
            record.weights_digest = data.fetch("weight_digest")
            record.adapter_digest = data["adapter_digest"].presence || "upstream:#{data.fetch('adapter_identifier')}"
            record.status = "reference"
          end

          run = mapping_for("model_run", data.fetch("model_run_id"), "Agevidence::ModelRun")&.internal_record
          run ||= project.model_runs.create!(
            model_adapter: adapter,
            task: "integration_model_run",
            status: data["status"] == "completed" ? "completed" : "failed",
            prompt_digest: data["prompt_digest"],
            retrieval_digest: data["input_manifest_digest"],
            input_manifest: { upstream_input_manifest_digest: data["input_manifest_digest"] },
            normalized_output: normalized_output_payload,
            output_digest: data.fetch("output_digest"),
            runtime_metadata: data.fetch("runtime_configuration", {}),
            completed_at: event.occurred_at,
            failure_reason: data["failure_reason"]
          )
          map_external!(external_object_type: "model_run", external_object_id: data.fetch("model_run_id"), record: run)
          import_candidates_and_gaps(run)

          receipt_request!(
            aggregate: run,
            receipt_type: "model_execution_receipt",
            schema_id: "athian.agevidence.model_execution.v1",
            payload: data.merge(
              event_id: event.external_event_id,
              project_internal_id: project.id,
              model_run_internal_id: run.id,
              limitations: Array(data["limitations"])
            )
          )
        end

        map_external!(external_object_type: "model_run_projection", external_object_id: data.fetch("model_run_id"), record: projection)
        result
      end

      private

      def normalized_output_payload
        {
          external_model_run_id: data.fetch("model_run_id"),
          limitations: Array(data["limitations"]),
          candidates: Array(data["candidates"]),
          gaps: Array(data["gaps"]),
          authority_boundary: "review_required"
        }
      end

      def import_candidates_and_gaps(run)
        Array(data["candidates"]).each do |candidate|
          run.evidence_candidates.find_or_create_by!(claim_text: candidate.fetch("claim_text")) do |record|
            record.candidate_type = candidate.fetch("candidate_type", "observation")
            record.source_references = Array(candidate["source_references"])
            record.model_confidence = candidate["confidence"]
            record.review_status = "review_required"
          end
        end

        Array(data["gaps"]).each do |gap|
          run.evidence_gaps.find_or_create_by!(requirement: gap.fetch("requirement")) do |record|
            record.gap_type = gap.fetch("gap_type", "missing_evidence")
            record.description = gap.fetch("description")
            record.severity = gap.fetch("severity", "material")
            record.source_context = gap.fetch("source_context", {})
            record.resolution_status = "open"
          end
        end
      end
    end
  end
end
