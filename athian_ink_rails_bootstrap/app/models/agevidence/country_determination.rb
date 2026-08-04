module Agevidence
  class CountryDetermination < ApplicationRecord
    STATUSES = %w[
      eligible eligible_with_conditions outside_current_method
      method_extension_required insufficient_evidence unassigned
    ].freeze

    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject"
    belongs_to :country_program, class_name: "Agevidence::CountryProgram"
    belongs_to :country_adapter, class_name: "Agevidence::CountryAdapter"
    belongs_to :country_method_version, class_name: "Agevidence::CountryMethodVersion"
    belongs_to :supersedes, class_name: "Agevidence::CountryDetermination", optional: true
    belongs_to :receipt, optional: true

    validates :status, :normalized_result, :evaluated_at, presence: true
    validates :status, inclusion: { in: STATUSES }

    before_update :prevent_mutation
    before_destroy :prevent_mutation

    def missing_evidence
      Array(normalized_result["missing_evidence"])
    end

    private

    def prevent_mutation
      errors.add(:base, "Country determinations are append-only; create a superseding determination instead.")
      throw :abort
    end
  end
end
