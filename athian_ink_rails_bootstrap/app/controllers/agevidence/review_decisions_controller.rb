module Agevidence
  class ReviewDecisionsController < BaseController
    def create
      candidate = EvidenceCandidate.find(params.require(:evidence_candidate_id))
      decision = candidate.review_decisions.create!(
        reviewer_role: params.require(:reviewer_role),
        decision: params.require(:decision),
        reason: params.require(:reason),
        policy_version: params[:policy_version].presence || "ATH-AGEV-POLICY-v1",
        decided_at: Time.current
      )
      ReceiptIssuer.new.issue_review_decision!(decision) if candidate.receipt
      record_campaign_activation { |recorder| recorder.record_review_decision_created(decision) }
      redirect_to agevidence_evidence_candidate_path(candidate), notice: "Append-only review decision recorded."
    rescue ActiveRecord::RecordInvalid, InkReceipts::Error, RuntimeError => e
      redirect_back fallback_location: agevidence_root_path, alert: e.message
    end
  end
end
