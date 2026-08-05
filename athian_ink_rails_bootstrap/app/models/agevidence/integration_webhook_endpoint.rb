module Agevidence
  class IntegrationWebhookEndpoint < ApplicationRecord
    STATUSES = %w[active paused revoked].freeze
    RESULT_EVENT_TYPES = %w[artifact.ready artifact.verification_failed reliance.recorded].freeze

    belongs_to :integration_source, class_name: "Agevidence::IntegrationSource"
    has_many :integration_webhook_deliveries, class_name: "Agevidence::IntegrationWebhookDelivery", dependent: :destroy

    serialize :event_types, coder: JSON

    validates :url, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
    validate :supported_event_types
    validate :safe_https_url

    scope :active, -> { where(status: "active") }

    def accepts?(event_type)
      event_types.blank? || event_types.include?(event_type)
    end

    private

    def supported_event_types
      unsupported = Array(event_types) - RESULT_EVENT_TYPES
      errors.add(:event_types, "contains unsupported values: #{unsupported.join(', ')}") if unsupported.any?
    end

    def safe_https_url
      uri = URI.parse(url.to_s)
      return if uri.is_a?(URI::HTTPS) && uri.host.present?

      errors.add(:url, "must be an absolute HTTPS URL")
    rescue URI::InvalidURIError
      errors.add(:url, "is invalid")
    end
  end
end
