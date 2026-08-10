class CountryAdapter < ApplicationRecord
  include Agevidence::Concerns::SingleActiveVersion

  belongs_to :country_program
  has_many :method_versions, class_name: 'CountryMethodVersion', foreign_key: :country_adapter_id
  has_many :claim_policies, class_name: 'CountryClaimPolicy', foreign_key: :country_adapter_id
  has_many :verification_profiles, class_name: 'CountryVerificationProfile', foreign_key: :country_adapter_id
  has_many :data_policies, class_name: 'CountryDataPolicy', foreign_key: :country_adapter_id
  has_many :determinations, class_name: 'CountryDetermination', foreign_key: :country_adapter_id

  validates :adapter_id, presence: true
  validates :version, presence: true
  validates :status, presence: true, inclusion: { in: %w[active pilot scaffold research superseded retired] }
  validates :manifest, presence: true

  scope :active, -> { where(status: 'active') }
  scope :by_country, ->(country_code) { joins(:country_program).where(country_programs: { country_code: country_code }) }

  single_active_version_scope :adapter_id

  def manifest_data
    @manifest_data ||= YAML.safe_load(manifest, aliases: true)
  end

  def method_version
    method_versions.active.first
  end

  def claim_policy
    claim_policies.active.first
  end

  def verification_profile
    verification_profiles.active.first
  end

  def data_policy
    data_policies.active.first
  end

  def artifact_profiles
    manifest_data.dig('adapter', 'artifact_profiles') || []
  end

  def limitations
    manifest_data.dig('adapter', 'limitations') || []
  end

  def applicability
    manifest_data.dig('adapter', 'applicability') || {}
  end

  def required_evidence
    manifest_data.dig('adapter', 'required_evidence') || []
  end

  def required_context
    applicability['required_context'] || {}
  end

  def excluded_context
    applicability['excluded_context'] || {}
  end
end