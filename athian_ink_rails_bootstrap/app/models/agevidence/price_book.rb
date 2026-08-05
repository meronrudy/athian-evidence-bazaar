module Agevidence
  class PriceBook < ApplicationRecord
    BILLING_MODELS = %w[one_time monthly annual usage].freeze

    has_many :artifact_orders, class_name: "Agevidence::ArtifactOrder", dependent: :restrict_with_exception
    has_many :subscriptions, class_name: "Agevidence::Subscription", dependent: :restrict_with_exception

    serialize :dimensions, coder: JSON

    validates :product_code, :version, :name, :currency, :billing_model, :effective_at, presence: true
    validates :product_code, uniqueness: { scope: :version }
    validates :billing_model, inclusion: { in: BILLING_MODELS }
    validates :base_amount_cents, :minimum_amount_cents, :included_units, :overage_amount_cents,
              numericality: { greater_than_or_equal_to: 0 }

    scope :active, -> { where(active: true).where("effective_at <= ?", Time.current).where("retired_at IS NULL OR retired_at > ?", Time.current) }

    def self.current!(product_code)
      active.where(product_code: product_code).order(effective_at: :desc, created_at: :desc).first!
    end

    def recurring?
      %w[monthly annual usage].include?(billing_model)
    end
  end
end
