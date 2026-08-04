class ClaimShare < ApplicationRecord
  belongs_to :claim_group

  validates :claimant_name, :claimant_role, :share_percent, presence: true
  validates :share_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :contribution_amount, numericality: { greater_than_or_equal_to: 0 }
end
