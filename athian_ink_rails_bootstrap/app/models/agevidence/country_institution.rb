module Agevidence
  class CountryInstitution < ApplicationRecord
    ROLES = %w[government registry verifier buyer lender sponsor insurer processor].freeze
    STATUSES = %w[scaffold active retired].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"

    validates :name, :institution_role, :status, presence: true
    validates :institution_role, inclusion: { in: ROLES }
    validates :status, inclusion: { in: STATUSES }
  end
end
