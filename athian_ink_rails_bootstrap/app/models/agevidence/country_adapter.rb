module Agevidence
  class CountryAdapter < ApplicationRecord
    STATUSES = Agevidence::CountryProgram::STATUSES

    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    belongs_to :country_method_version, class_name: "Agevidence::CountryMethodVersion", optional: true
    has_many :model_runs, class_name: "Agevidence::ModelRun", dependent: :nullify

    validates :adapter_id, :version, :status, presence: true
    validates :adapter_id, uniqueness: true
    validates :status, inclusion: { in: STATUSES }

    def display_name
      "#{country_program.code} #{adapter_id} #{version}"
    end
  end
end
