module Integrations
  module EventHandlers
    class InterventionRecordedHandler < BaseHandler
      def call
        project = developer_project
        projection = append_projection!(
          projection_type: "intervention",
          external_subject_id: data.fetch("intervention_id"),
          current_state: unit_present? ? state_for_parent(project) : "review_required",
          data_json: data.merge(project_mapping_present: project.present?, unit_review_required: !unit_present?)
        )
        map_external!(
          external_object_type: "intervention",
          external_object_id: data.fetch("intervention_id"),
          record: projection,
          metadata: { source_manifest_id: data["source_manifest_id"] }
        )

        if project
          receipt_request!(
            aggregate: projection,
            receipt_type: "intervention_receipt",
            schema_id: "athian.agevidence.intervention.v1",
            payload: data.merge(
              event_id: event.external_event_id,
              project_internal_id: project.id,
              authority_boundary: "records intervention occurrence only"
            )
          )
        end

        result
      end

      private

      def unit_present?
        data["unit"].present? && data["dose_or_quantity"].present?
      end
    end
  end
end
