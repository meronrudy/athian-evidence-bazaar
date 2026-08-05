module Agevidence
  class IntegrationEvent < ApplicationRecord
    EVENT_TYPES = %w[
      project.registered
      protocol.version_assigned
      source.manifest_available
      intervention.recorded
      model.run_completed
      verification.status_changed
      asset.status_changed
      producer.payment_recorded
    ].freeze
    PROCESSING_STATUSES = %w[accepted processing processed failed dead_letter].freeze

    belongs_to :integration_source, class_name: "Agevidence::IntegrationSource"
    has_many :receipt_outboxes, class_name: "Agevidence::ReceiptOutbox", dependent: :restrict_with_error
    has_many :integration_webhook_deliveries, class_name: "Agevidence::IntegrationWebhookDelivery", dependent: :nullify

    serialize :payload, coder: JSON
    serialize :correlation, coder: JSON

    validates :external_event_id, :operation_id, :event_type, :schema_version,
              :external_object_type, :external_object_id, :occurred_at, :received_at,
              :raw_envelope, :payload_digest, :signature, :processing_status, presence: true
    validates :external_event_id, uniqueness: { scope: :integration_source_id }
    validates :operation_id, uniqueness: true
    validates :event_type, inclusion: { in: EVENT_TYPES }
    validates :processing_status, inclusion: { in: PROCESSING_STATUSES }

    before_validation :assign_operation_id, on: :create

    def replayable?
      %w[processed failed dead_letter].include?(processing_status)
    end

    def accept_for_replay!
      update!(
        processing_status: "accepted",
        processing_error: nil,
        processed_at: nil
      )
    end

    private

    def assign_operation_id
      self.operation_id ||= "op_#{SecureRandom.hex(12)}"
    end
  end
end
