module Agevidence
  class ArtifactOrder < ApplicationRecord
    STATUSES = %w[quoted checkout_pending paid assembling fulfilled canceled expired payment_failed].freeze

    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount"
    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject", optional: true
    belongs_to :evidence_bundle, optional: true
    belongs_to :price_book, class_name: "Agevidence::PriceBook"
    has_many :usage_events, class_name: "Agevidence::UsageEvent", dependent: :nullify

    serialize :scope, coder: JSON
    serialize :pricing_input, coder: JSON
    serialize :pricing_breakdown, coder: JSON

    validates :external_id, :idempotency_key, :product_code, :status, :currency, presence: true
    validates :external_id, uniqueness: true
    validates :idempotency_key, uniqueness: { scope: :developer_account_id }
    validates :status, inclusion: { in: STATUSES }
    validates :quoted_amount_cents, numericality: { greater_than_or_equal_to: 0 }

    before_validation :assign_external_id, on: :create
    before_validation :assign_expiration, on: :create

    def payable?
      %w[quoted payment_failed].include?(status) && !expired?
    end

    def expired?
      expires_at.present? && expires_at.past?
    end

    def mark_paid!(payment_intent_id: nil)
      update!(status: "paid", paid_at: Time.current, payment_intent_id: payment_intent_id)
    end

    private

    def assign_external_id
      self.external_id ||= "aord_#{SecureRandom.hex(12)}"
    end

    def assign_expiration
      self.expires_at ||= 14.days.from_now
    end
  end
end
