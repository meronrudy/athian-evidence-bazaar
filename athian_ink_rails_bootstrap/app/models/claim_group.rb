class ClaimGroup < ApplicationRecord
  belongs_to :avsa
  has_many :claim_shares, dependent: :destroy

  accepts_nested_attributes_for :claim_shares

  validates :name, :verified_total, :unit, :aggregate_cap_percent, presence: true
  validates :aggregate_cap_percent, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :aggregate_claim_cap
  validate :aggregate_claim_exactness
  validate :claimants_are_unique

  def claimed_percent
    active_claim_shares.sum { |share| share.share_percent.to_d }
  end

  def remaining_percent
    [aggregate_cap_percent.to_d - claimed_percent, 0.to_d].max
  end

  def claimed_quantity
    verified_total.to_d * claimed_percent / 100
  end

  def remaining_quantity
    [verified_total.to_d - claimed_quantity, 0.to_d].max
  end

  def over_cap?
    claimed_percent > aggregate_cap_percent.to_d
  end

  def retirement_valid?
    retirement_status == "valid"
  end

  def exclusivity_valid?
    exclusivity_status == "valid"
  end

  def validation_results
    [
      { label: "totals = 100%", valid: claimed_percent == aggregate_cap_percent.to_d },
      { label: "no duplicate claimant", valid: duplicate_claimant_names.empty? },
      { label: "retirement valid", valid: retirement_valid? },
      { label: "exclusivity valid", valid: exclusivity_valid? }
    ]
  end

  private

  def aggregate_claim_cap
    return unless over_cap?

    errors.add(:base, "Aggregate claim shares cannot exceed #{aggregate_cap_percent}%")
  end

  def aggregate_claim_exactness
    return if active_claim_shares.empty?
    return if claimed_percent == aggregate_cap_percent.to_d

    errors.add(:base, "Aggregate claim shares must equal #{aggregate_cap_percent}%")
  end

  def claimants_are_unique
    duplicate_claimant_names.each do |name|
      errors.add(:base, "Duplicate claimant is not allowed: #{name}")
    end
  end

  def duplicate_claimant_names
    names = active_claim_shares.map { |share| share.claimant_name.to_s.strip.downcase }.reject(&:blank?)
    names.tally.select { |_name, count| count > 1 }.keys
  end

  def active_claim_shares
    claim_shares.reject(&:marked_for_destruction?)
  end
end
