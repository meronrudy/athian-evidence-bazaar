class OrganizationProfile < ApplicationRecord
  belongs_to :organization

  validates :organization, presence: true

  # Additional profile fields can be added here (logo, description, etc.)
end
