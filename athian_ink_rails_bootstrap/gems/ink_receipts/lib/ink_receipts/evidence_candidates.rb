module InkReceipts
  class << self
    def issue_evidence_candidate(payload:, parents: [], issuer:, signer:)
      Client.new.issue_agevidence(
        payload: payload,
        receipt_type: "evidence_candidate_receipt",
        schema: "athian.agevidence.evidence_candidate.v1",
        parents: parents,
        issuer: issuer,
        signer: signer
      )
    end
  end
end
