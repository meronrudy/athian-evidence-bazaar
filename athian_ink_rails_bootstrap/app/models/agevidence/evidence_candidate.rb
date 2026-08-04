module Agevidence
  class EvidenceCandidate < ApplicationRecord
    REVIEW_STATUSES = %w[review_required accepted rejected needs_more_evidence superseded].freeze

    belongs_to :model_run, class_name: "Agevidence::ModelRun"
    belongs_to :evidence_item, optional: true
    belongs_to :receipt, optional: true
    has_many :review_decisions, class_name: "Agevidence::ReviewDecision", dependent: :restrict_with_error

    validates :candidate_type, :claim_text, :review_status, presence: true
    validates :review_status, inclusion: { in: REVIEW_STATUSES }
    validates :model_confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

    def source_reference_labels
      Array(source_references).map { |reference| "#{reference['document_id']} #{reference['locator']}" }
    end
  end
end
