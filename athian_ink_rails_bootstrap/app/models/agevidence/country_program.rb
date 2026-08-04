module Agevidence
  class CountryProgram < ApplicationRecord
    STATUSES = %w[research draft pilot government_review accepted active superseded retired].freeze
    PHASES = %w[method_ready industry_led framework_forming high_complexity_scale].freeze

    has_many :country_methods, class_name: "Agevidence::CountryMethod", dependent: :destroy
    has_many :country_method_versions, through: :country_methods
    has_many :country_adapters, class_name: "Agevidence::CountryAdapter", dependent: :destroy
    has_many :country_institutions, class_name: "Agevidence::CountryInstitution", dependent: :destroy
    has_many :country_pilots, class_name: "Agevidence::CountryPilot", dependent: :destroy
    has_many :country_claim_policies, class_name: "Agevidence::CountryClaimPolicy", dependent: :destroy
    has_many :country_registries, class_name: "Agevidence::CountryRegistry", dependent: :destroy
    has_many :country_verification_profiles, class_name: "Agevidence::CountryVerificationProfile", dependent: :destroy
    has_many :country_data_policies, class_name: "Agevidence::CountryDataPolicy", dependent: :destroy
    has_many :developer_projects, class_name: "Agevidence::DeveloperProject", dependent: :nullify
    has_many :artifact_engagements, class_name: "Agevidence::ArtifactEngagement", dependent: :nullify

    validates :code, :country_name, :program_name, :priority, :phase, :status,
      :currency, :market_condition, :developer_proposition, presence: true
    validates :code, uniqueness: true
    validates :priority, uniqueness: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :phase, inclusion: { in: PHASES }
    validates :status, inclusion: { in: STATUSES }

    scope :ordered, -> { order(:priority) }

    def display_name
      "#{country_name} · #{program_name}"
    end

    def default_adapter
      preferred = %w[active accepted government_review pilot draft research]
      country_adapters.min_by { |adapter| preferred.index(adapter.status) || preferred.length }
    end

    def current_method_version
      preferred = %w[active accepted government_review pilot draft research]
      country_method_versions.min_by { |version| preferred.index(version.status) || preferred.length }
    end

    def launch_cell_by_seat
      country_institutions.order(:seat, :name).group_by(&:seat)
    end
  end
end
