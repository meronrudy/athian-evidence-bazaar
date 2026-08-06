module Agevidence
  class ArtifactOrder < ApplicationRecord
    STATUSES = %w[
      quoted
      checkout_pending
      paid
      assembling
      verification_pending
      fulfilled
      payment_failed
      canceled
      expired
    ].freeze

    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject"
    belongs_to :pricing_quote, class_name: "Agevidence::PricingQuote"
    belongs_to :artifact_engagement, class_name: "Agevidence::ArtifactEngagement", optional: true
    belongs_to :evidence_bundle, optional: true

    validates :external_id, :product_code, :status, :amount_cents, :currency, presence: true
    validates :external_id, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

    before_validation :assign_external_id, on: :create

    # Deprecated: Use Commercial::Orders::MarkPaid.call(order) instead.
    # This method is preserved for backward compatibility in sandbox tests.
    def checkout!
      pricing_quote.accept! unless pricing_quote.status == "accepted"
      update!(
        status: "paid",
        checkout_url: "sandbox://checkout/#{external_id}",
        checkout_completed_at: Time.current
      )
    end

    def fulfilled?
      status == "fulfilled"
    end

    private

    def assign_external_id
      self.external_id ||= "order_#{SecureRandom.alphanumeric(24).downcase}"
    end
  end
end
