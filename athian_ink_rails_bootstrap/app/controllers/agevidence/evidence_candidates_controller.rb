module Agevidence
  class EvidenceCandidatesController < BaseController
    before_action :set_candidate

    def show
      @project = @candidate.model_run.developer_project
      @decisions = @candidate.review_decisions.includes(:receipt).order(decided_at: :desc)
    end

    def update
      if @candidate.update(candidate_params)
        redirect_to agevidence_evidence_candidate_path(@candidate), notice: "Candidate projection updated."
      else
        @project = @candidate.model_run.developer_project
        @decisions = @candidate.review_decisions.order(decided_at: :desc)
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_candidate
      @candidate = EvidenceCandidate.includes(model_run: :developer_project).find(params[:id])
    end

    def candidate_params
      params.require(:evidence_candidate).permit(:review_status, :review_notes)
    end
  end
end
