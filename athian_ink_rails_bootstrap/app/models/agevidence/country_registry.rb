module Agevidence
  class CountryRegistry < ApplicationRecord
    STATUSES = %w[active pilot scaffold research unavailable retired].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"

    validates :name, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
  end
end
