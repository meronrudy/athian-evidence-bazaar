module Agevidence
  class CountryInstitution < ApplicationRecord
    SEATS = %w[commercial_anchor technology_anchor scientific_anchor government_standards_observer verification_anchor buyer_anchor athian].freeze
    TYPES = %w[operator startup university research_institute government standards_body verifier buyer processor cooperative producer_group investor insurer bank trading_company athian].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    has_many :reliance_events, class_name: "Agevidence::RelianceEvent", dependent: :nullify

    validates :name, :institution_type, :seat, :status, presence: true
    validates :name, uniqueness: { scope: :country_program_id }
    validates :institution_type, inclusion: { in: TYPES }
    validates :seat, inclusion: { in: SEATS }
  end
end
