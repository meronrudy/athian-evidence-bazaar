class VerificationRun < ApplicationRecord
  STATUSES = %w[valid invalid indeterminate].freeze
  MODES = %w[demo external ink_receipts].freeze

  belongs_to :avsa
  belongs_to :receipt, optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :verifier_mode, inclusion: { in: MODES }
  validates :started_at, :completed_at, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
end
