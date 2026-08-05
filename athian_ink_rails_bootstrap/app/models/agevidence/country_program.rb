module Agevidence
  class CountryProgram < ApplicationRecord
    STATUSES = %w[active pilot scaffold research retired].freeze

    has_many :country_methods, class_name: "Agevidence::CountryMethod", dependent: :destroy
    has_many :country_adapters, class_name: "Agevidence::CountryAdapter", dependent: :destroy
    has_many :country_institutions, class_name: "Agevidence::CountryInstitution", dependent: :destroy
    has_many :country_pilots, class_name: "Agevidence::CountryPilot", dependent: :destroy
    has_many :country_claim_policies, class_name: "Agevidence::CountryClaimPolicy", dependent: :destroy
    has_many :country_registries, class_name: "Agevidence::CountryRegistry", dependent: :destroy
    has_many :country_verification_profiles, class_name: "Agevidence::CountryVerificationProfile", dependent: :destroy
    has_many :country_data_policies, class_name: "Agevidence::CountryDataPolicy", dependent: :destroy
    has_many :developer_projects, class_name: "Agevidence::DeveloperProject", dependent: :nullify

    validates :name, :country_code, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
  end
end
