module Agevidence
  class RelianceEventsController < BaseController
    def create
      engagement = ArtifactEngagement.includes(:evidence_bundle).find(params.require(:artifact_engagement_id))
      raise "Assemble an evidence bundle before recording reliance." unless engagement.evidence_bundle

      event = engagement.reliance_events.create!(
        evidence_bundle: engagement.evidence_bundle,
        relying_party_name: params.require(:relying_party_name),
        relying_party_role: params.require(:relying_party_role),
        decision_type: params.require(:decision_type),
        outcome: params.require(:outcome),
        evidence_bundle_digest: engagement.evidence_bundle.evidence_bundle_digest,
        occurred_at: Time.current,
        notes: params[:notes]
      )
      ReceiptIssuer.new.issue_reliance_event!(event)
      redirect_to agevidence_developer_project_artifact_engagement_path(engagement.developer_project, engagement), notice: "External reliance event recorded."
    rescue ActiveRecord::RecordInvalid, RuntimeError, InkReceipts::Error => e
      redirect_back fallback_location: agevidence_root_path, alert: e.message
    end
  end
end
