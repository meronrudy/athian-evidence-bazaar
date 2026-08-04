module InkReceipts
  class << self
    def issue_country_adapter_commitment(payload:, parents: [], issuer:, signer:)
      Client.new.issue_agevidence(
        payload: payload,
        receipt_type: "country_adapter_commitment_receipt",
        schema: "athian.agevidence.country_adapter_commitment.v1",
        parents: parents,
        issuer: issuer,
        signer: signer
      )
    end

    def issue_country_determination(payload:, parents: [], issuer:, signer:)
      Client.new.issue_agevidence(
        payload: payload,
        receipt_type: "country_compatibility_determination_receipt",
        schema: "athian.country_determination.v1",
        parents: parents,
        issuer: issuer,
        signer: signer
      )
    end
  end
end
