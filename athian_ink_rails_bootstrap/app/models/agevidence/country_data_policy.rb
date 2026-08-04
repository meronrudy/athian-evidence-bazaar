module Agevidence
  class CountryDataPolicy < ApplicationRecord
    STATUSES = %w[active superseded retired scaffold].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    has_many :country_adapters, class_name: "Agevidence::CountryAdapter", dependent: :restrict_with_error

    validates :policy_id, :version, :status, presence: true
    validates :version, uniqueness: { scope: %i[country_program_id policy_id] }
    validates :status, inclusion: { in: STATUSES }
  end
end
