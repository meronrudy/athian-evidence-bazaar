module Agevidence
  class IntegrationArtifact < ApplicationRecord
    VERIFICATION_STATUSES = %w[valid invalid indeterminate].freeze
    RELIANCE_STATUSES = %w[not_yet_relied_upon relied_upon rejected superseded].freeze

    belongs_to :integration_source, class_name: "Agevidence::IntegrationSource"
    belongs_to :developer_project, class_name: "Agevidence::DeveloperProject", optional: true
    has_many :integration_webhook_deliveries, class_name: "Agevidence::IntegrationWebhookDelivery", dependent: :nullify

    serialize :manifest, coder: JSON

    validates :artifact_id, :external_project_id, :profile, :receipt_root,
              :verification_status, :policy_compatibility, :reliance_status,
              :download_token, :compiled_at, presence: true
    validates :artifact_id, :download_token, uniqueness: true
    validates :verification_status, inclusion: { in: VERIFICATION_STATUSES }
    validates :reliance_status, inclusion: { in: RELIANCE_STATUSES }

    before_validation :assign_identifiers, on: :create

    private

    def assign_identifiers
      self.artifact_id ||= "artifact_#{SecureRandom.hex(12)}"
      self.download_token ||= SecureRandom.urlsafe_base64(32)
    end
  end
end
