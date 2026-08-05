class ReceiptOutbox < ApplicationRecord
  STATUSES = %w[pending issuing issued verified failed dead_letter].freeze

  belongs_to :integration_event
  belongs_to :receipt, optional: true

  validates :aggregate_type,
            :receipt_type,
            :schema_id,
            :schema_version,
            :canonical_payload_json,
            :payload_digest,
            :idempotency_key,
            :status,
            presence: true
  validates :idempotency_key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :ready, -> { where(status: "pending").order(:created_at) }
end
