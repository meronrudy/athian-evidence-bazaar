module Agevidence
  class CountryAdapter < ApplicationRecord
    STATUSES = %w[scaffold active superseded retired].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    belongs_to :country_method_version, class_name: "Agevidence::CountryMethodVersion"
    belongs_to :country_claim_policy, class_name: "Agevidence::CountryClaimPolicy", optional: true
    belongs_to :country_verification_profile, class_name: "Agevidence::CountryVerificationProfile", optional: true
    belongs_to :country_data_policy, class_name: "Agevidence::CountryDataPolicy", optional: true
    belongs_to :commitment_receipt, class_name: "Receipt", optional: true
    has_many :country_determinations, class_name: "Agevidence::CountryDetermination", dependent: :restrict_with_error

    validates :adapter_id, :version, :status, :country_code, presence: true
    validates :version, uniqueness: { scope: :adapter_id }
    validates :status, inclusion: { in: STATUSES }

    def display_name
      "#{country_code} #{adapter_id} #{version}"
    end

    def required_evidence
      Array(manifest["required_evidence"])
    end

    def limitations
      Array(manifest["limitations"])
    end
  end
end
