module Agevidence
  class CountryMethod < ApplicationRecord
    STATUSES = Agevidence::CountryProgram::STATUSES

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    has_many :country_method_versions, class_name: "Agevidence::CountryMethodVersion", dependent: :destroy

    validates :code, :name, :authority, :scope, :status, presence: true
    validates :code, uniqueness: { scope: :country_program_id }
    validates :status, inclusion: { in: STATUSES }

    def display_name
      "#{code} · #{name}"
    end
  end
end
