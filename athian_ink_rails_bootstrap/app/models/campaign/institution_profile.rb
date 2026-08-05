module Campaign
  class InstitutionProfile < ApplicationRecord
    include MetadataBoundary

    belongs_to :campaign_country_program, class_name: "Campaign::CountryProgram"

    before_validation :assign_external_id, on: :create

    validates :external_id, :name, :institution_type, :status, presence: true
    validates :external_id, uniqueness: true
    validates :status, inclusion: { in: Campaign::CountryProgram::READINESS_STATES }
    validates_campaign_metadata :requirements_json, :limitations_json

    private

    def assign_external_id
      self.external_id ||= "inst_#{SecureRandom.alphanumeric(20).downcase}"
    end
  end
end
