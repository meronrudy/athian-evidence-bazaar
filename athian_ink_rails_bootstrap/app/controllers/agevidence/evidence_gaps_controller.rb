module Agevidence
  class EvidenceGapsController < BaseController
    before_action :set_gap

    def show; end

    def update
      if @gap.update(gap_params)
        redirect_to agevidence_evidence_gap_path(@gap), notice: "Gap resolution projection updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_gap
      @gap = EvidenceGap.includes(model_run: :developer_project).find(params[:id])
    end

    def gap_params
      params.require(:evidence_gap).permit(:resolution_status)
    end
  end
end
