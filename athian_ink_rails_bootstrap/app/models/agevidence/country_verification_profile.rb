module Agevidence
  class CountryVerificationProfile < ApplicationRecord
    STATUSES = %w[active pilot scaffold research superseded retired].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    has_many :country_adapters, class_name: "Agevidence::CountryAdapter", dependent: :restrict_with_error

    validates :profile_id, :version, :status, presence: true
    validates :version, uniqueness: { scope: %i[country_program_id profile_id] }
    validates :status, inclusion: { in: STATUSES }
  end
end
