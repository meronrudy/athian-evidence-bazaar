module V1
  module Campaign
    class QualificationsController < BaseController
      before_action :set_account

      def index
        render json: { qualifications: @account.technical_qualifications.order(created_at: :desc).map { |qualification| qualification_payload(qualification) } }
      end

      def create
        qualification = ::Campaign::TechnicalQualificationEvaluator.new(
          campaign_account: @account,
          developer_project: developer_project,
          options: qualification_options
        ).call
        render json: qualification_payload(qualification), status: :created
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, RuntimeError => e
        render_error("CAMPAIGN_QUALIFICATION_INVALID", status: :unprocessable_entity, message: e.message)
      end

      private

      def set_account
        @account = find_account!
      end

      def developer_project
        id = params.dig(:qualification, :developer_project_id).presence
        return nil unless id

        Agevidence::DeveloperProject.find(id)
      end

      def qualification_options
        return {} unless params[:qualification].present?

        params.require(:qualification).permit(
          :authoritative_system,
          :required_event_count,
          :country_code,
          :country_adapter_identifier,
          :named_obligation_code,
          :named_relying_party_type,
          :relying_party_type,
          :product_code,
          :scope_estimate,
          :reusable_mapping_identified,
          :accountable_buyer_or_sponsor,
          :timing_window,
          :permitted_commercial_handoff,
          :country_adapter_readiness,
          :institution_profile,
          :obligation_profile,
          :local_evidence_gap_count,
          :cross_country_portability_result
        )
      end
    end
  end
end
