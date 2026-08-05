module Agevidence
  class Subscription < ApplicationRecord
    STATUSES = %w[pending trialing active past_due paused canceled].freeze

    belongs_to :billing_account, class_name: "Agevidence::BillingAccount"
    belongs_to :price_book, class_name: "Agevidence::PriceBook"

    serialize :metadata, coder: JSON

    validates :status, inclusion: { in: STATUSES }
    validates :quantity, numericality: { greater_than: 0 }
  end
end
