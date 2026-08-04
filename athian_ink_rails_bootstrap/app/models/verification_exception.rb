class VerificationException < ApplicationRecord
  SEVERITIES = %w[low medium high critical].freeze
  STATUSES = %w[open accepted resolved].freeze

  belongs_to :avsa
  belongs_to :receipt, optional: true

  validates :code, :severity, :status, :description, presence: true
  validates :severity, inclusion: { in: SEVERITIES }
  validates :status, inclusion: { in: STATUSES }
end
