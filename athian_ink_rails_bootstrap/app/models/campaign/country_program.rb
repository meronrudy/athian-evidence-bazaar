module Campaign
  class CountryProgram < ApplicationRecord
    include MetadataBoundary

    READINESS_STATES = %w[
      research_not_started
      source_inventory
      policy_mapping
      schema_draft
      fixture_draft
      adapter_scaffold
      conformance_testing
      external_review
      campaign_ready
      production_ready
    ].freeze

    has_many :institution_profiles, class_name: "Campaign::InstitutionProfile", foreign_key: :campaign_country_program_id, dependent: :destroy
    has_many :obligation_profiles, class_name: "Campaign::ObligationProfile", foreign_key: :campaign_country_program_id, dependent: :destroy
    has_many :adapter_readiness_assessments, class_name: "Campaign::AdapterReadinessAssessment", foreign_key: :campaign_country_program_id, dependent: :destroy

    before_validation :normalize_country_code

    validates :country_code, :status, :research_status, :adapter_status, :publication_status, :developer_guide_status, :commercial_readiness, presence: true
    validates :country_code, uniqueness: true, format: { with: /\A[A-Z]{2}\z/ }
    validates :status, :research_status, :adapter_status, :publication_status, :developer_guide_status, :commercial_readiness,
              inclusion: { in: READINESS_STATES }
    validates_campaign_metadata :limitations_json

    private

    def normalize_country_code
      self.country_code = country_code.to_s.upcase.presence
    end
  end
end
