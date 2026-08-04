module Agevidence
  class ArtifactEngagement < ApplicationRecord
    PIPELINE_STAGES = %w[identified scoped proposed assembled relied_on converted closed].freeze
    BILLING_TYPES = %w[fixed_fee annual program event].freeze
    COMMERCIAL_STATUSES = %w[illustrative proposed active completed closed].freeze

    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject"
    belongs_to :country_program, class_name: "Agevidence::CountryProgram", optional: true
    belongs_to :evidence_bundle, optional: true
    has_many :reliance_events, class_name: "Agevidence::RelianceEvent", dependent: :destroy

    before_validation :inherit_country_program

    validates :product_code, :pipeline_stage, :billing_type, :currency, :commercial_status, presence: true
    validates :pipeline_stage, inclusion: { in: PIPELINE_STAGES }
    validates :billing_type, inclusion: { in: BILLING_TYPES }
    validates :commercial_status, inclusion: { in: COMMERCIAL_STATUSES }
    validates :list_price_cents, :quoted_price_cents, numericality: { greater_than_or_equal_to: 0 }

    def price_label
      quoted_price_cents.positive? ? quoted_price_cents : list_price_cents
    end

    private

    def inherit_country_program
      self.country_program ||= developer_project&.country_program
    end
  end
end
