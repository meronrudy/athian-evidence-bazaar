module Campaign
  class AdapterReadinessAssessment < ApplicationRecord
    include MetadataBoundary

    belongs_to :campaign_country_program, class_name: "Campaign::CountryProgram"

    before_validation :assign_external_id, on: :create

    validates :external_id, :adapter_identifier, :status, presence: true
    validates :external_id, uniqueness: true
    validates :status, inclusion: { in: Campaign::CountryProgram::READINESS_STATES }
    validates_campaign_metadata :unsupported_rules_json, :limitations_json

    private

    def assign_external_id
      self.external_id ||= "ready_#{SecureRandom.alphanumeric(20).downcase}"
    end
  end
end
