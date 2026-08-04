class EvidenceItem < ApplicationRecord
  DISCLOSURE_STATUSES = %w[public selective restricted withheld].freeze
  STATUSES = %w[present missing conflicted superseded revoked].freeze

  belongs_to :receipt

  validates :name, :evidence_type, :commitment, presence: true
  validates :disclosure_status, inclusion: { in: DISCLOSURE_STATUSES }
  validates :status, inclusion: { in: STATUSES }
end
