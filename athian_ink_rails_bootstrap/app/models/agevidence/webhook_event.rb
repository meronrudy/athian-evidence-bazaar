module Agevidence
  class WebhookEvent < ApplicationRecord
    STATUSES = %w[received processing processed failed ignored].freeze

    serialize :payload, coder: JSON

    validates :provider, :event_id, :event_type, :status, presence: true
    validates :event_id, uniqueness: { scope: :provider }
    validates :status, inclusion: { in: STATUSES }
  end
end
