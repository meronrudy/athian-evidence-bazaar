module Agevidence
  class CountryDataPolicy < ApplicationRecord
    belongs_to :country_program, class_name: "Agevidence::CountryProgram"

    validates :name, :version, :status, presence: true
    validates :name, uniqueness: { scope: [:country_program_id, :version] }
  end
end
