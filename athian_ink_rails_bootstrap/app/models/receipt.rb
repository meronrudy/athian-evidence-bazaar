class Receipt < ApplicationRecord
  LIFECYCLE_STATES = %w[
    draft observed validated attested sealed superseded revoked expired renewed
  ].freeze

  INTEGRITY_STATUSES = %w[valid invalid indeterminate].freeze
  CORE_CHAIN_TYPES = InkProjection::CORE_RECEIPT_TYPES

  belongs_to :avsa
  has_many :evidence_items, dependent: :destroy
  has_many :verification_runs, dependent: :nullify
  has_many :verification_exceptions, dependent: :nullify

  validates :receipt_type, :title, :sequence, :lifecycle_state, presence: true
  validates :sequence, uniqueness: { scope: :avsa_id }
  validates :lifecycle_state, inclusion: { in: LIFECYCLE_STATES }
  validates :integrity_status, inclusion: { in: INTEGRITY_STATUSES }

  scope :core_chain, -> { where(receipt_type: CORE_CHAIN_TYPES).order(:sequence) }
  scope :append_only, -> { where.not(receipt_type: CORE_CHAIN_TYPES).order(:sequence) }

  def parent_receipts
    avsa.receipts.where(id: parent_receipt_ids)
  end

  def evidence_complete?
    evidence_items.where(required: true).where.not(status: "present").none?
  end

  def portable_reference
    body_digest.presence || "receipt:#{id}"
  end

  def receipt_type_label
    receipt_type.to_s.humanize
  end

  def verified?
    integrity_status == "valid"
  end
end
