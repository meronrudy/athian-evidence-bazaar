module Agevidence
  class PricingQuote < ApplicationRecord
    STATUSES = %w[quoted accepted expired canceled].freeze
    PRICING_VERSION = "2026-08-01"

    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject"
    has_many :artifact_orders, class_name: "Agevidence::ArtifactOrder", dependent: :restrict_with_error

    validates :external_id, :product_code, :pricing_version, :currency, :amount_cents, :expires_at, :status, presence: true
    validates :external_id, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

    before_validation :assign_external_id, on: :create

    def expired?
      Time.current > expires_at
    end

    def accept!
      raise "Quote has expired." if expired?

      update!(status: "accepted", accepted_at: Time.current)
    end

    private

    def assign_external_id
      self.external_id ||= "quote_#{SecureRandom.alphanumeric(24).downcase}"
    end
  end
end
