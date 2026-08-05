class IntegrationSource < ApplicationRecord
  STATUSES = %w[active suspended retired].freeze
  SIGNATURE_ALGORITHMS = %w[hmac_sha256 ed25519].freeze

  has_many :integration_events, dependent: :restrict_with_error
  has_many :integration_operations, through: :integration_events
  has_many :external_object_mappings, dependent: :restrict_with_error
  has_many :integration_webhook_endpoints, dependent: :restrict_with_error

  validates :key, :name, :status, :signature_algorithm, presence: true
  validates :key, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :signature_algorithm, inclusion: { in: SIGNATURE_ALGORITHMS }

  def active_for_ingestion?
    status == "active"
  end

  def allows_event_type?(event_type)
    allowed = Array(allowed_event_types).reject(&:blank?)
    allowed.empty? || allowed.include?(event_type)
  end

  def verification_secret
    env_key = "ATHIAN_INTEGRATION_SECRET_#{key.upcase.gsub(/[^A-Z0-9]+/, "_")}"
    ENV[env_key].presence || verification_secret_ciphertext
  end
end
