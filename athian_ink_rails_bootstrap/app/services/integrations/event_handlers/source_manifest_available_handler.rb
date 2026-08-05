module Integrations
  module EventHandlers
    class SourceManifestAvailableHandler < BaseHandler
      def call
        project = developer_project
        projection = append_projection!(
          projection_type: "source_manifest",
          external_subject_id: data.fetch("manifest_id"),
          current_state: state_for_parent(project),
          data_json: data.merge(project_mapping_present: project.present?)
        )
        map_external!(
          external_object_type: "source_manifest",
          external_object_id: data.fetch("manifest_id"),
          record: projection,
          metadata: { source_systems: data["source_systems"] }
        )

        if project
          project.update!(integration_status: "source_registered")
          receipt_request!(
            aggregate: projection,
            receipt_type: "source_manifest_receipt",
            schema_id: "athian.agevidence.source_manifest.v1",
            payload: data.merge(
              event_id: event.external_event_id,
              project_internal_id: project.id,
              authority_boundary: "source records remain in upstream systems"
            )
          )
        end

        result
      end
    end
  end
end
