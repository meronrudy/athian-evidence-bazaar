module Agevidence
  class ReceiptOutboxDispatcher
    ARTIFACT_TRIGGER_EVENTS = %w[verification.status_changed asset.status_changed producer.payment_recorded].freeze

    def initialize(outbox)
      @outbox = outbox
    end

    def call
      outbox.with_lock do
        return outbox if outbox.status == "processed"

        outbox.update!(
          status: "processing",
          processing_error: nil,
          attempt_count: outbox.attempt_count + 1
        )

        issued = InkReceipts.issue(
          payload: outbox.canonical_payload,
          issuer: outbox.integration_event.integration_source.name,
          receipt_type: outbox.receipt_type,
          schema: outbox.schema_id,
          parents: Array(outbox.canonical_payload["parent_receipt_digests"]),
          lifecycle: "sealed",
          signer: "integration:#{outbox.integration_event.integration_source.key}"
        )
        verification = InkReceipts.verify(
          target: {
            checks: [
              {
                name: "issued_receipt_integrity",
                status: issued.fetch(:integrity_status, "indeterminate"),
                detail: issued.fetch(:body_digest)
              }
            ]
          }
        )
        receipt = persist_receipt_projection!(issued)

        outbox.update!(
          status: "processed",
          receipt: receipt,
          issued_receipt: issued,
          payload_digest: issued.fetch(:body_digest),
          verification_result: verification,
          processed_at: Time.current
        )
      end

      publish_result!
      outbox
    rescue StandardError => e
      mark_failed!(e)
      raise
    end

    private

    attr_reader :outbox

    def persist_receipt_projection!(issued)
      project_id = outbox.canonical_payload["internal_project_id"]
      project = DeveloperProject.find_by(id: project_id)
      avsa = project&.avsa
      return unless avsa

      avsa.with_lock do
        parent_receipts = ReceiptOutbox.where(
          payload_digest: Array(outbox.canonical_payload["parent_receipt_digests"])
        ).where.not(receipt_id: nil).includes(:receipt).map(&:receipt)

        avsa.receipts.create!(
          receipt_type: issued.fetch(:receipt_type),
          title: outbox.receipt_type.humanize,
          lifecycle_state: issued.fetch(:lifecycle_state),
          domain_state: "external_event_projected",
          issuer_name: issued.fetch(:issuer),
          signer_key_id: issued.fetch(:signer_key_id),
          schema_id: issued.fetch(:schema_id),
          schema_digest: issued.fetch(:schema_digest),
          body_digest: issued.fetch(:body_digest),
          evidence_commitment: issued.fetch(:evidence_commitment),
          policy_commitment: issued.fetch(:policy_commitment),
          trace_commitment: issued.fetch(:trace_commitment),
          sequence: avsa.receipts.maximum(:sequence).to_i + 1,
          parent_receipt_ids: parent_receipts.map(&:id),
          canonical_encoding_hex: issued.fetch(:canonical_encoding_hex),
          integrity_status: issued.fetch(:integrity_status),
          signed_at: Time.current,
          sealed_at: Time.current
        )
      end
    end

    def publish_result!
      status = outbox.verification_result["status"] || outbox.verification_result[:status]
      unless status == "valid"
        IntegrationWebhookDispatcher.enqueue_result!(
          source: outbox.integration_event.integration_source,
          integration_event: outbox.integration_event,
          event_type: "artifact.verification_failed",
          payload: {
            event_type: "artifact.verification_failed",
            external_project_id: outbox.aggregate_id,
            receipt_type: outbox.receipt_type,
            receipt_root: outbox.payload_digest,
            verification_status: status || "indeterminate",
            error: outbox.verification_result
          }
        )
        return
      end

      return unless ARTIFACT_TRIGGER_EVENTS.include?(outbox.integration_event.event_type)

      artifact = IntegrationArtifactCompiler.new(outbox).call
      IntegrationWebhookDispatcher.enqueue_artifact_ready!(artifact, outbox.integration_event)
    end

    def mark_failed!(error)
      attempts = [outbox.attempt_count, 1].max
      outbox.update_columns(
        status: attempts >= 5 ? "dead_letter" : "failed",
        processing_error: "#{error.class}: #{error.message}".truncate(4_000),
        updated_at: Time.current
      )
    rescue StandardError
      nil
    end
  end
end
