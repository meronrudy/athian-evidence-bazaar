class IntegrationWebhookEndpoint < ApplicationRecord
  STATUSES = %w[active paused disabled].freeze

  belongs_to :integration_source
  has_many :integration_deliveries, dependent: :restrict_with_error

  validates :url, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :url_is_https

  def signing_secret
    env_key = "ATHIAN_OUTBOUND_WEBHOOK_SECRET_#{integration_source.key.upcase.gsub(/[^A-Z0-9]+/, "_")}"
    ENV[env_key].presence || signing_secret_ciphertext
  end

  private

  def url_is_https
    uri = URI.parse(url)
    return if uri.is_a?(URI::HTTPS) && uri.host.present?

    errors.add(:url, "must be an https URL")
  rescue URI::InvalidURIError
    errors.add(:url, "must be valid")
  end
end
