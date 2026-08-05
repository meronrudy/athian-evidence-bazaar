module V1
  module Campaign
    class AccountsController < BaseController
      def index
        accounts = ::Campaign::Account.order(priority_score: :desc, updated_at: :desc)
        render json: { accounts: accounts.map { |account| account_payload(account) } }
      end

      def create
        account = ::Campaign::Account.create!(account_params)
        Array(params[:contact_refs]).each do |contact|
          account.contact_refs.create!(contact.permit(contact_ref_permitted))
        end
        render json: account_payload(account.reload, detail: true), status: :created
      rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
        render_error("CAMPAIGN_ACCOUNT_INVALID", status: :unprocessable_entity, message: e.message)
      end

      def show
        render json: account_payload(find_account!, detail: true)
      end

      def update
        account = find_account!
        account.update!(account_params)
        render json: account_payload(account.reload, detail: true)
      rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
        render_error("CAMPAIGN_ACCOUNT_INVALID", status: :unprocessable_entity, message: e.message)
      end

      private

      def account_params
        params.require(:campaign_account).permit(
          :external_id,
          :name,
          :domain,
          :country_code,
          :subsector,
          :funding_stage,
          :capital_raised_cents,
          :status,
          :qualification_level,
          :priority_score,
          :authoritative_system,
          :evidence_obligation_code,
          :evidence_obligation_summary,
          :salesforce_account_id,
          :apollo_account_id,
          :developer_account_id,
          metadata_json: {}
        )
      end

      def contact_ref_permitted
        [
          :external_id,
          :display_name,
          :role_category,
          :email_domain,
          :salesforce_contact_id,
          :apollo_person_id,
          :technical_authority,
          :commercial_authority,
          :scientific_authority,
          :contactability_status,
          :last_enriched_at,
          :last_synced_at,
          { metadata_json: {} }
        ]
      end
    end
  end
end
