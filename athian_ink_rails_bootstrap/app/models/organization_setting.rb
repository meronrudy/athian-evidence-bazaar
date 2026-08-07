class OrganizationSetting < ApplicationRecord
  belongs_to :organization

  # Settings stored as JSONB for flexibility
  attribute :settings, :jsonb, default: {}

  validates :organization, presence: true

  def self.for(organization)
    find_or_create_by(organization: organization)
  end

  def source_retention_days
    settings.fetch("source_retention_days", 365)
  end

  def artifact_retention_days
    settings.fetch("artifact_retention_days", 730)
  end
end
