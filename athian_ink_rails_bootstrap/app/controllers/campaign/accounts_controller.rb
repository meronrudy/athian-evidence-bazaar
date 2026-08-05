module Campaign
  class AccountsController < BaseController
    def index
      @accounts = Campaign::Account.includes(:developer_account, :activation_paths, :technical_qualifications, :commercial_handoffs)
                                   .order(priority_score: :desc, updated_at: :desc)
    end

    def show
      @account = Campaign::Account.includes(
        :developer_account,
        :contact_refs,
        :activation_paths,
        :touches,
        :technical_qualifications,
        :commercial_handoffs,
        :capability_attributions
      ).find(params[:id])
    end
  end
end
