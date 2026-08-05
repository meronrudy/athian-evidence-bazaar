class IntegrationEvent < ApplicationRecord
  PROCESSING_STATUSES = %w[
    received
    signature_invalid
    schema_invalid
    accepted
    processing
    processed
    failed
    dead_letter
    ignored_unknown_type
  ].freeze

  SIGNATURE_STATUSES = %w[unchecked valid invalid unsupported].freeze
  SCHEMA_STATUSES = %w[unchecked valid invalid unknown_event_type].freeze

  attr_readonly :integration_source_id,
                :external_event_id,
                :event_type,
                :schema_version,
                :external_object_type,
                :external_object_id,
                :occurred_at,
                :received_at,
                :raw_payload_json,
                :canonical_payload_json,
                :payload_digest,
                :provided_digest,
                :signature,
                :signature_algorithm,
                :supersedes_event_id,
                :correlation_json

  belongs_to :integration_source
  has_many :integration_operations, dependent: :restrict_with_error
  has_many :evidence_projections, foreign_key: :source_event_id, dependent: :restrict_with_error
  has_many :receipt_outboxes, dependent: :restrict_with_error

  validates :external_event_id,
            :event_type,
            :schema_version,
            :received_at,
            :raw_payload_json,
            :canonical_payload_json,
            :payload_digest,
            :signature_status,
            :schema_status,
            :processing_status,
            presence: true
  validates :external_event_id, uniqueness: { scope: :integration_source_id }
  validates :processing_status, inclusion: { in: PROCESSING_STATUSES }
  validates :signature_status, inclusion: { in: SIGNATURE_STATUSES }
  validates :schema_status, inclusion: { in: SCHEMA_STATUSES }

  def parsed_payload
    @parsed_payload ||= JSON.parse(raw_payload_json)
  end

  def data
    parsed_payload.fetch("data", {})
  end

  def subject
    parsed_payload.fetch("subject", {})
  end

  def correlation
    correlation_json.presence || parsed_payload.fetch("correlation", {})
  end

  def accepted_for_processing?
    processing_status == "accepted"
  end

  def replayable?
    signature_status == "valid" && %w[accepted processed failed dead_letter].include?(processing_status)
  end

  def primary_operation
    integration_operations.order(:created_at).first
  end

  def current_operation
    integration_operations.order(created_at: :desc).first
  end
end
