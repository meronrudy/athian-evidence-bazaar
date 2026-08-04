module Agevidence
  class CountryPilot < ApplicationRecord
    STATUSES = %w[scaffold planned active completed retired].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"

    validates :name, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
  end
end
