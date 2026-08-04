class InkProjection
  CORE_RECEIPT_TYPES = %w[
    practice_receipt
    measurement_receipt
    model_execution_receipt
    verifier_receipt
    issuance_receipt
    claim_receipt
    producer_payment_receipt
  ].freeze

  class << self
    def avsa(avsa)
      {
        id: avsa.id,
        external_id: avsa.external_id,
        title: avsa.title,
        producer: avsa.producer_name,
        protocol: avsa.protocol.display_name,
        methodology: avsa.methodology_label,
        verifier: avsa.vvb_name,
        buyer: avsa.buyer_name,
        status: avsa.status,
        verified_quantity: avsa.verified_quantity.to_s,
        unit: avsa.unit,
        reporting_period: avsa.reporting_period,
        root_digest: avsa.root_digest,
        local_verification_status: avsa.local_verification_status
      }
    end

    def receipt(receipt)
      {
        id: receipt.id,
        sequence: receipt.sequence,
        receipt_type: receipt.receipt_type,
        title: receipt.title,
        lifecycle_state: receipt.lifecycle_state,
        domain_state: receipt.domain_state,
        issuer: receipt.issuer_name,
        signer_key_id: receipt.signer_key_id,
        schema_id: receipt.schema_id,
        schema_digest: receipt.schema_digest,
        body_digest: receipt.body_digest,
        evidence_commitment: receipt.evidence_commitment,
        policy_commitment: receipt.policy_commitment,
        trace_commitment: receipt.trace_commitment,
        parent_receipt_ids: receipt.parent_receipt_ids,
        parent_digests: receipt.parent_receipts.map(&:body_digest),
        canonical_encoding_hex: receipt.canonical_encoding_hex,
        integrity_status: receipt.integrity_status,
        public_key: "#{receipt.signer_key_id.presence || 'did:key:athian-demo'}#public-key",
        trust_policy: "athian.ink.trust-policy.demo.v1",
        signed_at: receipt.signed_at&.iso8601,
        sealed_at: receipt.sealed_at&.iso8601,
        evidence: receipt.evidence_items.map { |item| evidence_item(item) }
      }
    end

    def evidence_item(item)
      {
        id: item.id,
        name: item.name,
        evidence_type: item.evidence_type,
        source_system: item.source_system,
        commitment: item.commitment,
        disclosure_status: item.disclosure_status,
        required: item.required?,
        status: item.status,
        captured_at: item.captured_at&.iso8601,
        metadata: item.metadata
      }
    end

    def claim_group(group)
      return nil unless group

      {
        id: group.id,
        name: group.name,
        verified_total: group.verified_total.to_s,
        unit: group.unit,
        aggregate_cap_percent: group.aggregate_cap_percent.to_s,
        claimed_percent: group.claimed_percent.to_s,
        remaining_percent: group.remaining_percent.to_s,
        finalization_status: group.finalization_status,
        prior_claim_check_status: group.prior_claim_check_status,
        retirement_status: group.retirement_status,
        exclusivity_status: group.exclusivity_status,
        validation_results: group.validation_results,
        shares: group.claim_shares.map do |share|
          {
            id: share.id,
            claimant_name: share.claimant_name,
            claimant_role: share.claimant_role,
            share_percent: share.share_percent.to_s,
            contribution_amount: share.contribution_amount.to_s,
            inventory_category: share.inventory_category,
            contract_right_digest: share.contract_right_digest,
            status: share.status
          }
        end
      }
    end

    def producer_payment(payment)
      return nil unless payment

      {
        id: payment.id,
        producer: payment.producer_name,
        gross_amount: payment.gross_amount.to_s,
        verification_deduction: payment.verification_deduction.to_s,
        platform_deduction: payment.platform_deduction.to_s,
        other_deductions: payment.other_deductions.to_s,
        net_amount: payment.net_amount.to_s,
        currency: payment.currency,
        status: payment.status,
        remittance_reference: payment.remittance_reference,
        paid_at: payment.paid_at&.iso8601
      }
    end

    def verification_target(target)
      if target.is_a?(Receipt)
        receipt_verification_target(target)
      else
        avsa_verification_target(target)
      end
    end

    private

    def receipt_verification_target(receipt)
      {
        reference: receipt.portable_reference,
        checks: [
          check("receipt.structure", receipt.body_digest.present?, "Receipt digest is present in the INK projection."),
          check("receipt.schema", receipt.schema_digest.present?, "Schema commitment is present."),
          check("receipt.evidence", receipt.evidence_complete? ? true : nil, "Required evidence is present."),
          check("receipt.parents", receipt.sequence == 1 || receipt.parent_receipt_ids.present?, "Parent relationship is declared."),
          check("receipt.integrity", integrity_boolean(receipt.integrity_status), "Receipt integrity status from INK projection.")
        ]
      }
    end

    def avsa_verification_target(avsa)
      receipts = avsa.receipts.includes(:evidence_items).order(:sequence)
      {
        reference: avsa.portable_reference,
        checks: [
          check("chain.receipts", receipts.any?, "At least one receipt exists."),
          check("chain.sequence", receipts.map(&:sequence) == (1..receipts.size).to_a, "Receipt sequence is contiguous."),
          check("chain.root", avsa.root_digest.present?, "AVSA root digest is present."),
          check("chain.evidence", receipts.all?(&:evidence_complete?) ? true : nil, "Every required evidence item is present."),
          check("chain.critical_exceptions", avsa.verification_exceptions.where(status: "open", severity: "critical").none?, "No open critical exception."),
          check("chain.terminal", receipts.where(receipt_type: CORE_RECEIPT_TYPES.last).first&.lifecycle_state == "sealed" ? true : nil, "Producer payment receipt is sealed.")
        ]
      }
    end

    def check(name, result, detail)
      status = result.nil? ? "indeterminate" : (result ? "valid" : "invalid")
      { name: name, status: status, detail: detail }
    end

    def integrity_boolean(status)
      return true if status == "valid"
      return false if status == "invalid"

      nil
    end
  end
end
