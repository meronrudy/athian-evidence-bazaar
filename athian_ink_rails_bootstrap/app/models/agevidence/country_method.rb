module Agevidence
  class CountryMethod < ApplicationRecord
    STATUSES = %w[scaffold active retired].freeze

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    has_many :country_method_versions, class_name: "Agevidence::CountryMethodVersion", dependent: :destroy

    validates :method_id, :name, :status, presence: true
    validates :method_id, uniqueness: { scope: :country_program_id }
    validates :status, inclusion: { in: STATUSES }
  end
end
