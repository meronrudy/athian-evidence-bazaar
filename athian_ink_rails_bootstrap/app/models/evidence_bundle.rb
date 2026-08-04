class EvidenceBundle < ApplicationRecord
  BUNDLE_TYPES = InkReceipts::BUNDLE_TYPES.keys.freeze
  STATUSES = %w[generated downloaded verified failed].freeze

  belongs_to :avsa

  validates :bundle_type, :name, :generated_at, :artifact_filename, presence: true
  validates :bundle_type, inclusion: { in: BUNDLE_TYPES }
  validates :status, inclusion: { in: STATUSES }
end
