module Agevidence
  class ReceiptIssuer
    def issue_model_execution!(model_run)
      payload = model_execution_payload(model_run)
      issued = InkReceipts.issue_model_execution(
        payload: payload,
        parents: [],
        issuer: "Athian AgEvidence Demo",
        signer: "did:key:athian-agevidence-demo"
      )
      receipt = create_receipt!(
        avsa: model_run.developer_project.avsa,
        issued: issued,
        title: "AgEvidence Model Execution Receipt",
        domain_state: "source_linked_candidates_generated",
        parents: []
      )
      model_run.update!(receipt: receipt, status: "receipt_issued")
      receipt
    end

    def issue_evidence_candidate!(candidate)
      issued = InkReceipts.issue_evidence_candidate(
        payload: evidence_candidate_payload(candidate),
        parents: [candidate.model_run.receipt&.body_digest].compact,
        issuer: "Athian AgEvidence Demo",
        signer: "did:key:athian-agevidence-demo"
      )
      receipt = create_receipt!(
        avsa: candidate.model_run.developer_project.avsa,
        issued: issued,
        title: "Evidence Candidate Receipt",
        domain_state: "candidate_extracted_for_review",
        parents: [candidate.model_run.receipt].compact
      )
      candidate.update!(receipt: receipt)
      receipt
    end

    def issue_review_decision!(decision)
      issued = InkReceipts.issue_review_decision(
        payload: review_decision_payload(decision),
        parents: [decision.evidence_candidate.receipt&.body_digest].compact,
        issuer: "Athian Scientific Review Demo",
        signer: "did:key:athian-review-demo"
      )
      receipt = create_receipt!(
        avsa: decision.evidence_candidate.model_run.developer_project.avsa,
        issued: issued,
        title: "Human Review Receipt",
        domain_state: "human_review_decision_appended",
        parents: [decision.evidence_candidate.receipt].compact
      )
      decision.update_column(:receipt_id, receipt.id)
      receipt
    end

    def issue_reliance_event!(event)
      issued = InkReceipts.issue_reliance_event(
        payload: reliance_event_payload(event),
        parents: [event.evidence_bundle.acceptance_receipt&.body_digest].compact,
        issuer: "Athian Reliance Demo",
        signer: "did:key:athian-reliance-demo"
      )
      create_receipt!(
        avsa: event.evidence_bundle.avsa,
        issued: issued,
        title: "Reliance Event Receipt",
        domain_state: "external_reliance_recorded",
        parents: [event.evidence_bundle.acceptance_receipt].compact
      )
    end

    private

    def model_execution_payload(model_run)
      metadata = model_run.runtime_metadata
      {
        base_model_id: model_run.model_adapter.base_model_id,
        weights_digest: model_run.model_adapter.weights_digest,
        adapter_id: model_run.model_adapter.adapter_id,
        adapter_digest: model_run.model_adapter.adapter_digest,
        model_license: model_run.model_adapter.license,
        runtime: metadata["runtime"],
        generation_config: { temperature: 0, seed: 42 },
        system_prompt_digest: model_run.prompt_digest,
        retrieval_corpus_digest: model_run.retrieval_digest,
        source_document_commitments: input_documents(model_run).map { |document| document.fetch("commitment") { document.fetch(:commitment) } },
        normalized_output_digest: model_run.output_digest,
        policy_version: "ATH-AGEV-POLICY-v1",
        parent_receipts: [],
        limitations: model_run.limitations,
        execution_timestamp: model_run.completed_at&.iso8601,
        issuer: "Athian AgEvidence Demo",
        signer: "did:key:athian-agevidence-demo"
      }
    end

    def evidence_candidate_payload(candidate)
      {
        candidate_id: "candidate-#{candidate.id}",
        candidate_type: candidate.candidate_type,
        claim_text: candidate.claim_text,
        source_references: candidate.source_references,
        model_confidence: candidate.model_confidence,
        model_run_receipt: candidate.model_run.receipt&.body_digest,
        review_status: candidate.review_status
      }
    end

    def review_decision_payload(decision)
      {
        candidate_receipt: decision.evidence_candidate.receipt&.body_digest,
        reviewer_role: decision.reviewer_role,
        decision: decision.decision,
        reason: decision.reason,
        protocol_version: decision.evidence_candidate.model_run.developer_project.protocol&.display_name,
        policy_version: decision.policy_version,
        unresolved_gaps: decision.evidence_candidate.model_run.evidence_gaps.where.not(resolution_status: "resolved").pluck(:requirement),
        timestamp: decision.decided_at.iso8601,
        signer: "did:key:athian-review-demo"
      }
    end

    def reliance_event_payload(event)
      {
        artifact_digest: event.evidence_bundle.evidence_bundle_digest,
        relying_institution: event.relying_party_name,
        decision_type: event.decision_type,
        outcome: event.outcome,
        declared_scope: event.artifact_engagement.product_code,
        limitations: ["Recorded reliance is an external event projection, not recognized revenue."],
        timestamp: event.occurred_at.iso8601
      }
    end

    def create_receipt!(avsa:, issued:, title:, domain_state:, parents:)
      raise "AVSA is required to persist a receipt projection" unless avsa

      avsa.receipts.create!(
        receipt_type: issued.fetch(:receipt_type),
        title: title,
        lifecycle_state: issued.fetch(:lifecycle_state),
        domain_state: domain_state,
        issuer_name: issued.fetch(:issuer),
        signer_key_id: issued.fetch(:signer_key_id),
        schema_id: issued.fetch(:schema_id),
        schema_digest: issued.fetch(:schema_digest),
        body_digest: issued.fetch(:body_digest),
        evidence_commitment: issued.fetch(:evidence_commitment),
        policy_commitment: issued.fetch(:policy_commitment),
        trace_commitment: issued.fetch(:trace_commitment),
        sequence: avsa.receipts.maximum(:sequence).to_i + 1,
        parent_receipt_ids: parents.map(&:id),
        canonical_encoding_hex: issued.fetch(:canonical_encoding_hex),
        integrity_status: issued.fetch(:integrity_status),
        signed_at: Time.current,
        sealed_at: issued.fetch(:lifecycle_state) == "sealed" ? Time.current : nil
      )
    end

    def input_documents(model_run)
      model_run.input_manifest["documents"] || model_run.input_manifest[:documents] || []
    end
  end
end
