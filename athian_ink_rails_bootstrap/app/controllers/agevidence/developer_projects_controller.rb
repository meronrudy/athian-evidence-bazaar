module Agevidence
  class DeveloperProjectsController < BaseController
    before_action :set_project, only: %i[show edit update destroy]

    def index
      @projects = DeveloperProject.includes(:developer_account, :protocol, :avsa).order(updated_at: :desc)
    end

    def show
      @model_runs = @project.model_runs.includes(:model_adapter, :receipt, :evidence_candidates, :evidence_gaps).order(created_at: :desc)
      @candidates = EvidenceCandidate.joins(:model_run).where(agevidence_model_runs: { developer_project_id: @project.id }).order(:id)
      @gaps = EvidenceGap.joins(:model_run).where(agevidence_model_runs: { developer_project_id: @project.id }).order(:id)
      @engagements = @project.artifact_engagements.includes(:evidence_bundle).order(created_at: :desc)
      @source_records = @project.source_records.order(:document_id)
      @pricing_quotes = @project.pricing_quotes.order(created_at: :desc)
      @artifact_orders = @project.artifact_orders.includes(:pricing_quote, :evidence_bundle).order(created_at: :desc)
      @country_programs = CountryProgram.includes(:country_adapters).order(:country_code, :name)
      @country_determinations = @project.country_determinations.includes(:country_program, :country_adapter, :receipt).order(evaluated_at: :desc)
      @product_notice = product_notice
    end

    def new
      @project = DeveloperProject.new(
        developer_account_id: params[:developer_account_id],
        protocol_status: "mapping",
        integration_status: "not_started"
      )
      load_form_options
    end

    def create
      @project = DeveloperProject.new(project_params)
      if @project.save
        redirect_to agevidence_developer_project_path(@project), notice: "Developer project created."
      else
        load_form_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_options
    end

    def update
      if @project.update(project_params)
        redirect_to agevidence_developer_project_path(@project), notice: "Developer project updated."
      else
        load_form_options
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @project.destroy
      redirect_to agevidence_developer_projects_path, notice: "Developer project removed from the scaffold."
    end

    private

    def set_project
      @project = DeveloperProject.find(params[:id])
    end

    def load_form_options
      CountryAdapterCatalog.sync! if CountryProgram.none?
      @accounts = DeveloperAccount.order(:name)
      @protocols = Protocol.order(:code)
      @avsas = Avsa.order(:external_id)
      @country_programs = CountryProgram.order(:country_code, :name)
    end

    def project_params
      params.require(:developer_project).permit(
        :developer_account_id, :protocol_id, :avsa_id, :country_program_id, :primary_country_program_id,
        :name, :project_type, :commercialization_stage, :target_claim, :protocol_status,
        :integration_status, country_context: {}
      )
    end
  end
end
