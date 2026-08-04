module Agevidence
  class ReviewDecision < ApplicationRecord
    DECISIONS = %w[accepted rejected needs_more_evidence superseded].freeze

    belongs_to :evidence_candidate, class_name: "Agevidence::EvidenceCandidate"
    belongs_to :receipt, optional: true

    validates :reviewer_role, :decision, :reason, :policy_version, :decided_at, presence: true
    validates :decision, inclusion: { in: DECISIONS }

    after_create :project_decision_to_candidate
    before_update :prevent_mutation
    before_destroy :prevent_mutation

    private

    def project_decision_to_candidate
      evidence_candidate.update!(
        review_status: decision,
        review_notes: reason,
        reviewed_by: reviewer_role,
        reviewed_at: decided_at
      )
    end

    def prevent_mutation
      errors.add(:base, "Review decisions are append-only; create a superseding decision instead.")
      throw :abort
    end
  end
end
