module Agevidence
  class DeveloperAccountsController < BaseController
    before_action :set_account, only: %i[show edit update destroy]

    def index
      @accounts = DeveloperAccount.includes(:developer_projects).order(:name)
    end

    def show
      @projects = @account.developer_projects.includes(:protocol, :avsa)
    end

    def new
      @account = DeveloperAccount.new(status: "active")
    end

    def create
      @account = DeveloperAccount.new(account_params)
      if @account.save
        redirect_to agevidence_developer_account_path(@account), notice: "Developer account created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @account.update(account_params)
        redirect_to agevidence_developer_account_path(@account), notice: "Developer account updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @account.destroy
      redirect_to agevidence_developer_accounts_path, notice: "Developer account archived from the scaffold."
    end

    private

    def set_account
      @account = DeveloperAccount.find(params[:id])
    end

    def account_params
      params.require(:developer_account).permit(
        :name, :website, :funding_stage, :capital_raised_cents, :primary_segment, :headquarters, :status
      )
    end
  end
end
