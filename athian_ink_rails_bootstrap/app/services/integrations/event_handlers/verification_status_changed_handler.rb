module Integrations
  module EventHandlers
    class VerificationStatusChangedHandler < BaseHandler
      def call
        project = developer_project
        projection = append_projection!(
          projection_type: "verification",
          external_subject_id: data.fetch("verification_engagement_id"),
          current_state: verification_state,
          data_json: data.merge(project_mapping_present: project.present?)
        )
        map_external!(
          external_object_type: "verification_engagement",
          external_object_id: data.fetch("verification_engagement_id"),
          record: projection,
          external_version: data["criteria_version"]
        )

        if project
          create_exceptions(project)
          receipt_request!(
            aggregate: projection,
            receipt_type: "verification_determination_receipt",
            schema_id: "athian.agevidence.verification_determination.v1",
            payload: data.merge(
              event_id: event.external_event_id,
              project_internal_id: project.id,
              authority_boundary: "verifier status is upstream-declared and append-only"
            )
          )
        end

        result
      end

      private

      def verification_state
        case data["status"]
        when "validated", "verified" then "complete"
        when "rejected", "withdrawn" then "blocked"
        when "superseded" then "superseded"
        else "review_required"
        end
      end

      def create_exceptions(project)
        return unless project.avsa

        Array(data["exceptions"]).each do |exception|
          project.avsa.verification_exceptions.find_or_create_by!(
            code: exception.fetch("code"),
            description: exception["description"].presence || exception.fetch("reference", "Verifier exception")
          ) do |record|
            record.severity = severity(exception["materiality"])
            record.status = "open"
            record.materiality = exception["materiality"]
            record.owner = data["verifier_id"]
          end
        end
      end

      def severity(materiality)
        materiality == "critical" ? "critical" : "high"
      end
    end
  end
end
