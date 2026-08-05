module Agevidence
  class ReceiptOutboxProcessor
    class ProcessingError < StandardError; end

    def initialize(receipt_outbox:)
      @receipt_outbox = receipt_outbox
    end

    def call
      receipt_outbox.with_lock do
        return receipt_outbox if %w[verified dead_letter].include?(receipt_outbox.status)

        receipt_outbox.update!(status: "issuing", attempt_count: receipt_outbox.attempt_count + 1)
        verify_payload_commitment!
        issued = issue_receipt
        receipt = persist_receipt!(issued)
        verification = InkVerifier.new(target: receipt).call
        receipt_outbox.update!(
          status: verification.fetch(:status) == "valid" ? "verified" : "failed",
          receipt: receipt,
          receipt_digest: receipt.body_digest,
          verification_status: verification.fetch(:status),
          verification_result_json: verification,
          issued_at: Time.current,
          last_error_code: nil,
          last_error_message: nil
        )
      end
    rescue StandardError => e
      receipt_outbox.update!(
        status: receipt_outbox.attempt_count >= 3 ? "dead_letter" : "failed",
        last_error_code: "RECEIPT_OUTBOX_PROCESSING_FAILED",
        last_error_message: e.message
      )
      raise e
    end

    private

    attr_reader :receipt_outbox

    def payload
      @payload ||= receipt_outbox.canonical_payload_json.deep_stringify_keys
    end

    def verify_payload_commitment!
      canonical = InkReceipts.canonicalize_integration_event(payload)
      expected = InkReceipts.integration_payload_digest(canonical)
      return if expected == receipt_outbox.payload_digest

      raise ProcessingError, "Receipt outbox payload commitment mismatch."
    end

    def issue_receipt
      InkReceipts.issue(
        payload: payload,
        issuer: "Athian Integration Bridge",
        receipt_type: receipt_outbox.receipt_type,
        schema: receipt_outbox.schema_id,
        parents: parent_receipts.map(&:body_digest),
        lifecycle: "sealed",
        avsa: avsa.external_id,
        signer: "did:key:athian-integration-bridge"
      )
    end

    def persist_receipt!(issued)
      existing = Receipt.find_by(body_digest: issued.fetch(:body_digest))
      return existing if existing

      avsa.with_lock do
        avsa.receipts.create!(
          receipt_type: issued.fetch(:receipt_type),
          title: receipt_outbox.receipt_type.humanize,
          lifecycle_state: issued.fetch(:lifecycle_state),
          domain_state: "integration_event_projected",
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

    def parent_receipts
      @parent_receipts ||= avsa.receipts.order(:sequence).last ? [avsa.receipts.order(:sequence).last] : []
    end

    def avsa
      @avsa ||= begin
        project = developer_project
        raise ProcessingError, "Receipt outbox cannot resolve a developer project." unless project

        project.avsa || create_lightweight_avsa!(project)
      end
    end

    def developer_project
      return Agevidence::DeveloperProject.find_by(id: payload["project_internal_id"]) if payload["project_internal_id"].present?

      mapping = ExternalObjectMapping.find_by(
        integration_source: receipt_outbox.integration_event.integration_source,
        external_object_type: "project",
        external_object_id: payload["project_id"],
        internal_record_type: "Agevidence::DeveloperProject"
      )
      mapping&.internal_record
    end

    def create_lightweight_avsa!(project)
      protocol = project.protocol || Protocol.find_or_create_by!(code: "ATH-INTEGRATION") do |record|
        record.name = "Athian Integration Projection Protocol"
        record.version = "v1"
        record.governance_version = "ATH-INTEGRATION-2026.1"
        record.status = "active"
        record.description = "Lightweight protocol projection used only to anchor event-derived receipt projections."
      end

      avsa = Avsa.create!(
        protocol: protocol,
        external_id: "AVSA-INTEGRATION-#{project.id}",
        title: project.name,
        producer_name: project.developer_account.name,
        status: "in_progress",
        verified_quantity: 0,
        unit: "tCO2e",
        local_verification_status: "indeterminate",
        methodology_name: protocol.name,
        methodology_version: protocol.version
      )
      project.update!(avsa: avsa, protocol: protocol)
      avsa
    end
  end
end
