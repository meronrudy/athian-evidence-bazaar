module Integrations
  module EventHandlers
    class ProtocolVersionAssignedHandler < BaseHandler
      def call
        project = developer_project
        protocol = Protocol.find_or_create_by!(code: data.fetch("protocol_id")) do |record|
          record.name = data["protocol_name"].presence || data.fetch("protocol_id")
          record.version = data.fetch("version")
          record.governance_version = data["governance_version"].presence || "UPSTREAM-#{data.fetch('version')}"
          record.status = "active"
          record.effective_on = data["effective_from"]
          record.description = "Protocol projection assigned by upstream integration event."
        end
        project&.update!(protocol: protocol, protocol_status: "mapping")

        map_external!(
          external_object_type: "protocol_version",
          external_object_id: data.fetch("protocol_version_id"),
          record: protocol,
          external_version: data.fetch("version"),
          metadata: { methodology_reference: data["methodology_reference"], country_code: data["country_code"] }
        )

        append_projection!(
          projection_type: "protocol_version",
          external_subject_id: data.fetch("protocol_version_id"),
          current_state: state_for_parent(project),
          data_json: data.merge(project_mapping_present: project.present?)
        )

        result
      end
    end
  end
end
