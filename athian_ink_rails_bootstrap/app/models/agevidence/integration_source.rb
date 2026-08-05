module Agevidence
  class IntegrationSource < ApplicationRecord
    SIGNING_ALGORITHMS = %w[hmac_sha256 ed25519].freeze
    STATUSES = %w[active paused revoked].freeze

    belongs_to :developer_account, class_name: "Agevidence::DeveloperAccount"
    has_many :integration_events, class_name: "Agevidence::IntegrationEvent", dependent: :restrict_with_error
    has_many :external_object_mappings, class_name: "Agevidence::ExternalObjectMapping", dependent: :restrict_with_error
    has_many :integration_artifacts, class_name: "Agevidence::IntegrationArtifact", dependent: :restrict_with_error
    has_many :integration_webhook_endpoints, class_name: "Agevidence::IntegrationWebhookEndpoint", dependent: :destroy

    validates :key, :name, :environment, :signing_algorithm, :status, presence: true
    validates :key, uniqueness: true
    validates :signing_algorithm, inclusion: { in: SIGNING_ALGORITHMS }
    validates :status, inclusion: { in: STATUSES }
    validate :verification_material_present

    scope :active, -> { where(status: "active") }

    def active?
      status == "active"
    end

    def resolved_verification_key
      return verification_key if verification_key.present?
      return if verification_key_reference.blank?

      credential = Rails.application.credentials.dig(*verification_key_reference.split("."))
      credential.presence || ENV[verification_key_reference]
    end

    private

    def verification_material_present
      return if verification_key.present? || verification_key_reference.present?

      errors.add(:base, "verification key or secret-manager reference is required")
    end
  end
end
