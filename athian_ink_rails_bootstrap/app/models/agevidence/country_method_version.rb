module Agevidence
  class CountryMethodVersion < ApplicationRecord
    STATUSES = Agevidence::CountryProgram::STATUSES

    belongs_to :country_method, class_name: "Agevidence::CountryMethod"
    has_one :country_program, through: :country_method
    has_many :country_adapters, class_name: "Agevidence::CountryAdapter", dependent: :nullify
    has_many :protocols, dependent: :nullify
    has_many :country_pilots, class_name: "Agevidence::CountryPilot", dependent: :nullify
    has_many :country_claim_policies, class_name: "Agevidence::CountryClaimPolicy", dependent: :nullify
    has_many :country_registries, class_name: "Agevidence::CountryRegistry", dependent: :nullify
    has_many :country_verification_profiles, class_name: "Agevidence::CountryVerificationProfile", dependent: :nullify
    has_many :reliance_events, class_name: "Agevidence::RelianceEvent", dependent: :nullify

    validates :version, :status, presence: true
    validates :version, uniqueness: { scope: :country_method_id }
    validates :status, inclusion: { in: STATUSES }

    def display_name
      "#{country_method.code} #{version}"
    end
  end
end
