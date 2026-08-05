require "digest"
require "ink_receipts/integration_events"

module Agevidence
  class IntegrationArtifactCompiler
    def initialize(trigger_outbox)
      @trigger_outbox = trigger_outbox
    end

    def call
      source = trigger_outbox.integration_event.integration_source
      artifact_id = "artifact_#{Digest::SHA256.hexdigest(trigger_outbox.idempotency_key).first(24)}"
      existing = IntegrationArtifact.find_by(artifact_id: artifact_id)
      return existing if existing

      outboxes = ReceiptOutbox.joins(:integration_event)
                               .where(aggregate_id: trigger_outbox.aggregate_id, status: "processed")
                               .where(agevidence_integration_events: { integration_source_id: source.id })
                               .order(:created_at)
      receipts = outboxes.map do |record|
        {
          idempotency_key: record.idempotency_key,
          receipt_type: record.receipt_type,
          schema_id: record.schema_id,
          body_digest: record.payload_digest,
          issued_receipt: record.issued_receipt,
          verification_result: record.verification_result
        }
      end
      receipt_root = InkReceipts::IntegrationEvents.canonical_digest(
        receipts.map { |receipt| receipt.fetch(:body_digest) }
      )
      verification_status = aggregate_verification_status(outboxes)
      event_data = trigger_outbox.integration_event.payload.fetch("data", {})
      country = trigger_outbox.integration_event.correlation["country_code"].to_s.downcase.presence || "global"
      profile = event_data["artifact_profile"].presence || "verification-readiness.#{country}.v1"
      policy_compatibility = event_data["policy_compatibility"].presence || event_data["status"].presence || "review_required"
      project = DeveloperProject.find_by(id: trigger_outbox.canonical_payload["internal_project_id"])

      manifest = {
        contract: "athian.integration.artifact.v1",
        artifact_id: artifact_id,
        profile: profile,
        external_project_id: trigger_outbox.aggregate_id,
        integration_source: source.key,
        compiled_at: Time.current.iso8601,
        receipt_root: receipt_root,
        verification_status: verification_status,
        policy_compatibility: policy_compatibility,
        reliance_status: "not_yet_relied_upon",
        receipt_count: receipts.length,
        receipts: receipts,
        verification_command: "agevidence verify artifact.json",
        limitations: [
          "The upstream Athian platform remains the operational system of record.",
          "Cryptographic validity, method compatibility, and institutional reliance remain separate states."
        ]
      }

      IntegrationArtifact.create!(
        integration_source: source,
        developer_project: project,
        artifact_id: artifact_id,
        external_project_id: trigger_outbox.aggregate_id,
        profile: profile,
        receipt_root: receipt_root,
        verification_status: verification_status,
        policy_compatibility: policy_compatibility,
        reliance_status: "not_yet_relied_upon",
        manifest: manifest,
        compiled_at: Time.current
      )
    end

    private

    attr_reader :trigger_outbox

    def aggregate_verification_status(outboxes)
      statuses = outboxes.map do |record|
        record.verification_result["status"] || record.verification_result[:status] || "indeterminate"
      end
      return "invalid" if statuses.include?("invalid")
      return "indeterminate" if statuses.include?("indeterminate")

      "valid"
    end
  end
end
