module Agevidence
  class CountryRegistry < ApplicationRecord
    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    belongs_to :country_method_version, class_name: "Agevidence::CountryMethodVersion", optional: true

    validates :name, :authority, :status, presence: true
    validates :name, uniqueness: { scope: :country_program_id }
  end
end
