class IntegrationDelivery < ApplicationRecord
  STATUSES = %w[pending delivering delivered retrying failed dead_letter].freeze

  belongs_to :integration_webhook_endpoint

  validates :event_type, :external_id, :idempotency_key, :status, presence: true
  validates :external_id, :idempotency_key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
end
