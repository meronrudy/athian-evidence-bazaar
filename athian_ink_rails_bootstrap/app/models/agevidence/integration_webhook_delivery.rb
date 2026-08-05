module Agevidence
  class IntegrationWebhookDelivery < ApplicationRecord
    STATUSES = %w[pending processing delivered failed dead_letter].freeze

    belongs_to :integration_webhook_endpoint, class_name: "Agevidence::IntegrationWebhookEndpoint"
    belongs_to :integration_event, class_name: "Agevidence::IntegrationEvent", optional: true
    belongs_to :integration_artifact, class_name: "Agevidence::IntegrationArtifact", optional: true

    serialize :payload, coder: JSON

    validates :event_type, :idempotency_key, :status, presence: true
    validates :idempotency_key, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    scope :deliverable, -> { where(status: %w[pending failed]) }
  end
end
