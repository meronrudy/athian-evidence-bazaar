class Organization < ApplicationRecord
  TYPES = %w[
    agtech_provider
    producer
    project_developer
    buyer
    verifier
    research_institution
    government_program
    registry
    consultancy
    internal
  ].freeze

  STATUSES = %w[active suspended archived].freeze

  has_many :organization_profiles, dependent: :destroy
  has_many :organization_settings, dependent: :destroy
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :developer_projects, class_name: "Agevidence::DeveloperProject", dependent: :destroy
  has_many :source_records, class_name: "Agevidence::SourceRecord", dependent: :destroy
  has_many :model_runs, class_name: "Agevidence::ModelRun", dependent: :destroy
  has_many :pricing_quotes, class_name: "Agevidence::PricingQuote", dependent: :destroy
  has_many :artifact_orders, class_name: "Agevidence::ArtifactOrder", dependent: :destroy
  has_many :api_credentials, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :organization_type, presence: true, inclusion: { in: TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :sandbox, inclusion: { in: [true, false] }

  before_validation :generate_external_id, on: :create
  before_validation :generate_slug, on: :create

  scope :sandbox, -> { where(sandbox: true) }
  scope :production, -> { where(sandbox: false) }

  def self.create_from_developer_account(developer_account)
    create!(
      legal_name: developer_account.name,
      display_name: developer_account.name,
      organization_type: "project_developer",
      sandbox: developer_account.status == "synthetic_demo"
    )
  end

  private

  def generate_external_id
    self.external_id ||= "org_#{SecureRandom.alphanumeric(16).downcase}"
  end

  def generate_slug
    self.slug ||= display_name.parameterize if display_name.present?
  end
end
