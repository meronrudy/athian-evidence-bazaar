module V1
  module Developer
    class ProjectsController < BaseController
      def create
        account = developer_account
        project = account.developer_projects.create!(
          name: project_params.fetch(:name),
          project_type: project_params[:project_type].presence || "intervention",
          commercialization_stage: project_params[:commercialization_stage].presence || "sandbox",
          target_claim: project_params[:target_claim].presence || "Developer-submitted agricultural evidence claim",
          protocol_status: project_params[:protocol_status].presence || "mapping",
          integration_status: "source_registered",
          country_context: project_params[:country_context].presence || {}
        )
        map_project!(project)
        record_campaign_activation { |recorder| recorder.record_project_created(project) }
        render json: project_payload(project), status: :created
      rescue ActiveRecord::RecordInvalid, KeyError => e
        render_error("DEVELOPER_PROJECT_INVALID", status: :unprocessable_entity, message: e.message)
      end

      def show
        project = find_project!
        render json: project_payload(project).merge(
          source_records: project.source_records.order(:document_id).map { |record| source_record_payload(record) },
          model_runs: project.model_runs.order(created_at: :desc).map { |run| model_run_payload(run) },
          quotes: project.pricing_quotes.order(created_at: :desc).map { |quote| quote_payload(quote) },
          orders: project.artifact_orders.order(created_at: :desc).map { |order| order_payload(order) }
        )
      end

      private

      def developer_account
        account_params = if params[:developer_account].present?
                           params.require(:developer_account).permit(:name, :website, :funding_stage, :capital_raised_cents, :primary_segment, :headquarters)
                         else
                           {}
                         end
        name = account_params[:name].presence || params[:developer_account_name].presence || "Sandbox Developer"
        Agevidence::DeveloperAccount.find_or_create_by!(name: name) do |account|
          account.website = account_params[:website]
          account.funding_stage = account_params[:funding_stage].presence || "sandbox"
          account.capital_raised_cents = account_params[:capital_raised_cents]
          account.primary_segment = account_params[:primary_segment].presence || "self_service_developer"
          account.headquarters = account_params[:headquarters]
          account.status = "active"
        end
      end

      def project_params
        @project_params ||= params.require(:project).permit(
          :name,
          :external_project_id,
          :project_type,
          :commercialization_stage,
          :target_claim,
          :protocol_status,
          country_context: {}
        )
      end

      def map_project!(project)
        external_id = project_params[:external_project_id].presence || "developer-project-#{project.id}"
        ExternalObjectMapping.find_or_create_by!(
          integration_source: developer_integration_source,
          external_object_type: "project",
          external_object_id: external_id,
          internal_record_type: "Agevidence::DeveloperProject"
        ) do |mapping|
          mapping.internal_record_id = project.id
          mapping.first_seen_at = Time.current
          mapping.last_seen_at = Time.current
          mapping.metadata_json = { origin: "developer_api" }
        end
      end
    end
  end
end
