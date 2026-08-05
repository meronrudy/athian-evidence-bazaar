module Integrations
  module EventHandlers
    class AssetStatusChangedHandler < BaseHandler
      def call
        projection = append_projection!(
          projection_type: "asset",
          external_subject_id: data.fetch("asset_id"),
          current_state: state_for_parent(developer_project),
          data_json: data.merge(authority_boundary: "asset ledger remains upstream")
        )
        map_external!(
          external_object_type: "asset",
          external_object_id: data.fetch("asset_id"),
          record: projection,
          metadata: { status: data["status"], registry_reference: data["registry_reference"] }
        )
        result
      end
    end
  end
end
