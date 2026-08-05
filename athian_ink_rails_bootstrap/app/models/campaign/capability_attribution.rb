module Campaign
  class CapabilityAttribution < ApplicationRecord
    include MetadataBoundary

    CAPABILITY_TYPES = %w[
      event_schema
      source_record_type
      country_adapter
      python_sdk_method
      cli_command
      integration_guide
      reference_fixture
      artifact_profile
      webhook_contract
      verification_profile
    ].freeze

    belongs_to :campaign_account, class_name: "Campaign::Account"
    belongs_to :campaign_commercial_handoff, class_name: "Campaign::CommercialHandoff", optional: true

    validates :capability_type, :capability_identifier, :repository_sha, presence: true
    validates :capability_type, inclusion: { in: CAPABILITY_TYPES }
    validates :repository_sha, format: { with: /\A[a-f0-9]{7,40}\z/ }
    validates :contracted_value_cents, :cash_collected_cents, :support_minutes, :reuse_count,
              numericality: { greater_than_or_equal_to: 0 }
    validates_campaign_metadata :metadata_json
  end
end
