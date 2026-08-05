module Integrations
  module EventHandlers
    class ProjectRegisteredHandler < BaseHandler
      def call
        account = Agevidence::DeveloperAccount.find_or_create_by!(name: producer_name) do |record|
          record.status = "synthetic_demo"
          record.primary_segment = "Upstream integration projection"
          record.headquarters = data["country_code"]
        end

        project = mapped_project || account.developer_projects.create!(
          name: data.fetch("project_name"),
          project_type: "intervention",
          commercialization_stage: "upstream_operational_projection",
          target_claim: data["target_claim"].presence || "Upstream project evidence chain",
          protocol_status: "mapping",
          integration_status: "source_registered",
          country_context: { country_code: data["country_code"] }
        )
        project.update!(integration_status: "source_registered") unless project.integration_status == "source_registered"

        map_external!(
          external_object_type: "project",
          external_object_id: data.fetch("project_id"),
          record: project,
          external_version: data["external_version"],
          metadata: { producer_id: data["producer_id"], source_authority: "upstream_system" }
        )

        append_projection!(
          projection_type: "project",
          external_subject_id: data.fetch("project_id"),
          current_state: "complete",
          data_json: data.merge(authority_boundary: "upstream platform remains system of record")
        )

        result
      end

      private

      def mapped_project
        mapping_for("project", data["project_id"], "Agevidence::DeveloperProject")&.internal_record
      end

      def producer_name
        data["producer_name"].presence || "Upstream Producer #{data.fetch('producer_id')}"
      end
    end
  end
end
