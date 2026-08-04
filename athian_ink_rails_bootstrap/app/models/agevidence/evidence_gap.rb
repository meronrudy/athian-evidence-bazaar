module Agevidence
  class EvidenceGap < ApplicationRecord
    SEVERITIES = %w[low medium material critical].freeze
    RESOLUTION_STATUSES = %w[open in_review resolved superseded].freeze

    belongs_to :model_run, class_name: "Agevidence::ModelRun"

    validates :gap_type, :requirement, :description, :severity, :resolution_status, presence: true
    validates :severity, inclusion: { in: SEVERITIES }
    validates :resolution_status, inclusion: { in: RESOLUTION_STATUSES }
  end
end
