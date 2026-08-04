class ProducerPayment < ApplicationRecord
  STATUSES = %w[pending approved processing remitted failed disputed].freeze

  belongs_to :avsa

  validates :producer_name, :gross_amount, :net_amount, :currency, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :net_reconciles

  def total_deductions
    verification_deduction.to_d + platform_deduction.to_d + other_deductions.to_d
  end

  def producer_share_percent
    return 0 if gross_amount.to_d.zero?

    (net_amount.to_d / gross_amount.to_d * 100).round(1)
  end

  private

  def net_reconciles
    expected = gross_amount.to_d - total_deductions
    return if expected == net_amount.to_d

    errors.add(:net_amount, "must equal gross amount minus deductions")
  end
end
