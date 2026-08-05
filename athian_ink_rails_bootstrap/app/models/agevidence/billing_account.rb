module Agevidence
  class BillingAccount < ApplicationRecord
    STATUSES = %w[pending active past_due suspended closed].freeze

    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount"
    has_many :subscriptions, class_name: "Agevidence::Subscription", dependent: :destroy

    serialize :metadata, coder: JSON

    validates :provider, :status, :currency, presence: true
    validates :developer_account_id, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :payment_terms_days, :monthly_commitment_cents, numericality: { greater_than_or_equal_to: 0 }
  end
end
