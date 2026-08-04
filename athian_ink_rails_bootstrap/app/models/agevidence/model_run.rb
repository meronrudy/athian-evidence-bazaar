module Agevidence
  class ModelRun < ApplicationRecord
    STATUSES = %w[queued running completed failed receipt_issued superseded].freeze

    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject"
    belongs_to :model_adapter, class_name: "Agevidence::ModelAdapter"
    belongs_to :receipt, optional: true
    has_many :evidence_candidates, class_name: "Agevidence::EvidenceCandidate", dependent: :destroy
    has_many :evidence_gaps, class_name: "Agevidence::EvidenceGap", dependent: :destroy

    validates :task, :status, presence: true
    validates :status, inclusion: { in: STATUSES }

    def limitations
      Array(normalized_output["limitations"])
    end
  end
end
