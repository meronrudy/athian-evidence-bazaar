module Agevidence
  class ModelRunsController < BaseController
    before_action :set_project, only: %i[new create]

    def new
      @adapters = ModelAdapter.order(:adapter_id)
    end

    def create
      adapter = ModelAdapter.find(params.require(:model_adapter_id))
      run = ModelRunIngestion.new(project: @project, model_adapter: adapter).call
      redirect_to agevidence_model_run_path(run), notice: "Fixture-backed model run ingested."
    rescue KeyError, ActiveRecord::RecordInvalid, RuntimeError => e
      @adapters = ModelAdapter.order(:adapter_id)
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    def show
      @model_run = ModelRun.includes(:model_adapter, :receipt, evidence_candidates: :receipt, evidence_gaps: []).find(params[:id])
      @project = @model_run.developer_project
    end

    def issue_receipt
      @model_run = ModelRun.find(params[:id])
      receipt = ReceiptIssuer.new.issue_model_execution!(@model_run)
      @model_run.evidence_candidates.find_each { |candidate| ReceiptIssuer.new.issue_evidence_candidate!(candidate) unless candidate.receipt }
      redirect_to agevidence_model_run_path(@model_run), notice: "Model Execution and candidate receipts issued through ink_receipts. Latest receipt: #{receipt.id}."
    rescue InkReceipts::Error, RuntimeError => e
      redirect_to agevidence_model_run_path(@model_run), alert: e.message
    end

    private

    def set_project
      @project = DeveloperProject.find(params[:developer_project_id])
    end
  end
end
