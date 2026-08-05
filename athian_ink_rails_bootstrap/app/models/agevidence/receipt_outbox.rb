module Agevidence
  class ReceiptOutbox < ApplicationRecord
    STATUSES = %w[pending processing processed failed dead_letter].freeze

    belongs_to :integration_event, class_name: "Agevidence::IntegrationEvent"
    belongs_to :receipt, optional: true

    serialize :canonical_payload, coder: JSON
    serialize :issued_receipt, coder: JSON
    serialize :verification_result, coder: JSON

    validates :aggregate_type, :aggregate_id, :receipt_type, :schema_id,
              :idempotency_key, :status, presence: true
    validates :idempotency_key, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    scope :dispatchable, -> { where(status: %w[pending failed]) }
  end
end
