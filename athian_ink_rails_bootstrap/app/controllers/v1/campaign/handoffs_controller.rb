module V1
  module Campaign
    class HandoffsController < BaseController
      before_action :set_account

      def index
        render json: { handoffs: @account.commercial_handoffs.order(created_at: :desc).map { |handoff| handoff_payload(handoff) } }
      end

      def create
        qualification = @account.technical_qualifications.find_by!(external_id: handoff_params.require(:qualification_id))
        handoff = ::Campaign::CommercialHandoffCreator.new(
          campaign_account: @account,
          qualification: qualification,
          product_code: handoff_params.require(:product_code),
          planning_value_cents: handoff_params[:planning_value_cents].to_i,
          currency: handoff_params[:currency].presence || "USD",
          scope: handoff_params[:scope].presence || {}
        ).call
        render json: handoff_payload(handoff.reload), status: :created
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ActionController::ParameterMissing, RuntimeError => e
        render_error("CAMPAIGN_HANDOFF_INVALID", status: :unprocessable_entity, message: e.message)
      end

      private

      def set_account
        @account = find_account!
      end

      def handoff_params
        @handoff_params ||= params.require(:handoff).permit(:qualification_id, :product_code, :planning_value_cents, :currency, scope: {})
      end
    end
  end
end
