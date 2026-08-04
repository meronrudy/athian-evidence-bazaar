class Avsa < ApplicationRecord
  STATUSES = %w[in_progress verification_pending certified finalized reversed].freeze
  VERIFICATION_STATUSES = %w[valid invalid indeterminate].freeze

  belongs_to :protocol
  has_many :receipts, -> { order(:sequence) }, dependent: :destroy
  has_one :claim_group, dependent: :destroy
  has_many :verification_runs, dependent: :destroy
  has_many :verification_exceptions, dependent: :destroy
  has_many :evidence_bundles, dependent: :destroy
  has_many :methodology_migrations, dependent: :destroy
  has_one :producer_payment, dependent: :destroy

  validates :external_id, :title, :producer_name, :unit, presence: true
  validates :external_id, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :local_verification_status, inclusion: { in: VERIFICATION_STATUSES }

  def pending_attestation_count
    receipts.where(lifecycle_state: %w[validated attested]).count
  end

  def open_exception_count
    verification_exceptions.where(status: "open").count
  end

  def sealed_receipts_count
    receipts.where(lifecycle_state: "sealed").count
  end

  def receipt_count
    receipts.size
  end

  def portable_reference
    root_digest.presence || external_id
  end

  def methodology_label
    name = methodology_name.presence || protocol.name
    version = methodology_version.presence || protocol.version
    "#{name} #{version}"
  end
end
