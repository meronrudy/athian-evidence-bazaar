module Agevidence
  class DeterminationsController < BaseController
    def index
      @determinations = CountryDetermination.includes(:developer_project, :country_program, :country_adapter, :receipt)
                                             .order(evaluated_at: :desc)
    end

    def show
      @determination = CountryDetermination.includes(:developer_project, :country_program, :country_adapter, :country_method_version, :receipt)
                                           .find(params[:id])
      @project = @determination.developer_project
      @artifact_order = @project.artifact_orders.includes(:evidence_bundle).order(created_at: :desc).detect(&:evidence_bundle)
      @model_run = @project.model_runs.order(created_at: :desc).first
    end
  end
end
