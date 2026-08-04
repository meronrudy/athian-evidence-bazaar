module Agevidence
  class CountryProgramsController < BaseController
    before_action :ensure_catalog_loaded
    before_action :set_country_program, only: %i[show evaluate]

    def index
      @country_programs = CountryProgram.includes(:country_adapters, :country_methods).order(:country_code, :name)
    end

    def show
      @country_adapters = @country_program.country_adapters.includes(
        :country_method_version,
        :country_claim_policy,
        :country_verification_profile,
        :country_data_policy,
        :commitment_receipt
      ).order(:adapter_id, :version)
      @projects = DeveloperProject.includes(:developer_account, :country_determinations)
                                  .where("country_program_id = ? OR primary_country_program_id = ?", @country_program.id, @country_program.id)
      @determinations = CountryDetermination.includes(:developer_project, :country_adapter, :receipt)
                                             .where(country_program: @country_program)
                                             .order(evaluated_at: :desc)
      @latest_adapter = @country_adapters.first
      @artifact_profile = @latest_adapter ? CountryAdapterCatalog.artifact_profile(@latest_adapter) : {}
    end

    def evaluate
      project = DeveloperProject.find(params.require(:developer_project_id))
      adapter = @country_program.country_adapters.find(params.require(:country_adapter_id))
      project.update!(country_program: @country_program, primary_country_program: @country_program)
      determination = CountryDeterminationAppender.new(project: project, country_adapter: adapter).call
      redirect_to agevidence_country_program_path(@country_program), notice: "Country determination appended: #{determination.status.humanize}."
    rescue ActiveRecord::RecordInvalid, KeyError, RuntimeError, InkReceipts::Error => e
      redirect_to agevidence_country_program_path(@country_program), alert: e.message
    end

    private

    def ensure_catalog_loaded
      CountryAdapterCatalog.sync! if CountryProgram.none?
    end

    def set_country_program
      @country_program = CountryProgram.find(params[:id])
    end
  end
end
