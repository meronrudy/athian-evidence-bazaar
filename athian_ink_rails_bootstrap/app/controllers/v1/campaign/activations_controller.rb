module V1
  module Campaign
    class ActivationsController < BaseController
      before_action :set_account

      def index
        render json: { activations: @account.activation_paths.order(updated_at: :desc).map { |activation| activation_payload(activation) } }
      end

      def create
        activation = @account.activation_paths.create!(activation_params.merge(status: activation_params[:status].presence || "started", started_at: activation_params[:started_at].presence || Time.current))
        @account.touches.create!(
          touch_type: activation.status == "completed" ? "quickstart_completed" : "quickstart_started",
          source_system: "campaign_api",
          external_reference: activation.external_id,
          repository_sha: activation.repository_sha,
          content_reference: activation.guide_path,
          occurred_at: Time.current,
          metadata_json: { "path_type" => activation.path_type }
        )
        render json: activation_payload(activation), status: :created
      rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
        render_error("CAMPAIGN_ACTIVATION_INVALID", status: :unprocessable_entity, message: e.message)
      end

      def complete
        activation = @account.activation_paths.find_by!(external_id: params[:external_id])
        activation.complete!
        @account.touches.create!(
          touch_type: activation.path_type == "cli_project_4030" ? "cli_replay_completed" : "quickstart_completed",
          source_system: "campaign_api",
          external_reference: activation.external_id,
          repository_sha: activation.repository_sha,
          content_reference: activation.guide_path,
          occurred_at: Time.current,
          metadata_json: { "path_type" => activation.path_type }
        )
        render json: activation_payload(activation)
      end

      def fail
        activation = @account.activation_paths.find_by!(external_id: params[:external_id])
        activation.fail!(code: params[:failure_code].presence || "activation_failed")
        render json: activation_payload(activation)
      end

      private

      def set_account
        @account = find_account!
      end

      def activation_params
        params.require(:activation).permit(
          :external_id,
          :path_type,
          :status,
          :repository_sha,
          :guide_path,
          :sdk_version,
          :cli_version,
          :developer_project_external_id,
          :invited_at,
          :started_at,
          :completed_at,
          :failed_at,
          :failure_code,
          :support_minutes,
          metadata_json: {}
        )
      end
    end
  end
end
