class EvidenceProjection < ApplicationRecord
  PROJECTION_TYPES = %w[
    project
    protocol_version
    project_protocol_assignment
    source_manifest
    intervention
    model_run
    verification
    asset
    producer_payment
  ].freeze
  STATES = %w[complete pending_parent stale superseded indeterminate review_required blocked].freeze

  belongs_to :source_event, class_name: "IntegrationEvent"
  belongs_to :supersedes_projection, class_name: "EvidenceProjection", optional: true

  validates :projection_type,
            :current_state,
            :source_event_digest,
            :projection_version,
            :projected_at,
            presence: true
  validates :projection_type, inclusion: { in: PROJECTION_TYPES }
  validates :current_state, inclusion: { in: STATES }
end
