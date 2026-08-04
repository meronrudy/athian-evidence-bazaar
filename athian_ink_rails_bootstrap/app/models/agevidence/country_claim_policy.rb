module Agevidence
  class CountryClaimPolicy < ApplicationRecord
    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    belongs_to :country_method_version, class_name: "Agevidence::CountryMethodVersion", optional: true
    has_many :evidence_bundles, dependent: :nullify

    validates :name, :version, :status, :authority_statement, presence: true
    validates :name, uniqueness: { scope: [:country_program_id, :version] }
  end
end
