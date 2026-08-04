module Agevidence
  class RelianceEvent < ApplicationRecord
    ROLES = %w[protocol vvb buyer auditor sponsor insurer].freeze
    OUTCOMES = %w[accepted relied_on rejected needs_more_evidence].freeze

    belongs_to :artifact_engagement, class_name: "Agevidence::ArtifactEngagement"
    belongs_to :evidence_bundle

    validates :relying_party_name, :relying_party_role, :decision_type, :outcome, :occurred_at, presence: true
    validates :relying_party_role, inclusion: { in: ROLES }
    validates :outcome, inclusion: { in: OUTCOMES }

    after_create :mark_bundle_reliance

    private

    def mark_bundle_reliance
      evidence_bundle.update!(
        reliance_status: outcome,
        relying_party_count: evidence_bundle.relying_party_count.to_i + 1,
        accepted_at: occurred_at
      )
      artifact_engagement.update!(pipeline_stage: "relied_on", commercial_status: "completed")
    end
  end
end
