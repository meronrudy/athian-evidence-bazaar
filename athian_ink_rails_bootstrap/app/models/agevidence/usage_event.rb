module Agevidence
  class UsageEvent < ApplicationRecord
    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount"
    belongs_to :api_client, class_name: "Agevidence::ApiClient", optional: true
    belongs_to :artifact_order, class_name: "Agevidence::ArtifactOrder", optional: true

    serialize :metadata, coder: JSON

    validates :event_type, :product_code, :unit, :idempotency_key, :occurred_at, presence: true
    validates :idempotency_key, uniqueness: { scope: :developer_account_id }
    validates :quantity, numericality: { greater_than: 0 }

    scope :during, ->(range) { where(occurred_at: range) }
  end
end
