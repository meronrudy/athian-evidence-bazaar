module V1
  module Developer
    class CandidatesController < BaseController
      def show
        candidate = Agevidence::EvidenceCandidate.includes(:review_decisions, :model_run).find(params[:id])
        render json: candidate_payload(candidate).merge(
          review_decisions: candidate.review_decisions.order(:decided_at).map { |decision| decision_payload(decision) }
        )
      end

      def update
        candidate = Agevidence::EvidenceCandidate.find(params[:id])
        decision = candidate.review_decisions.create!(
          reviewer_role: review_params[:reviewer_role].presence || "scientific_reviewer_sandbox",
          decision: review_params.require(:decision),
          reason: review_params[:reason].presence || "Developer API sandbox review decision.",
          policy_version: review_params[:policy_version].presence || "athian.agevidence.review.sandbox.v1",
          decided_at: Time.current
        )
        record_campaign_activation { |recorder| recorder.record_review_decision_created(decision) }
        render json: candidate_payload(candidate.reload).merge(latest_decision: decision_payload(decision))
      rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
        render_error("REVIEW_DECISION_INVALID", status: :unprocessable_entity, message: e.message)
      end

      private

      def review_params
        @review_params ||= params.require(:review_decision).permit(:reviewer_role, :decision, :reason, :policy_version)
      end

      def decision_payload(decision)
        {
          id: decision.id,
          reviewer_role: decision.reviewer_role,
          decision: decision.decision,
          reason: decision.reason,
          policy_version: decision.policy_version,
          receipt_id: decision.receipt_id,
          decided_at: decision.decided_at&.iso8601
        }
      end
    end
  end
end
