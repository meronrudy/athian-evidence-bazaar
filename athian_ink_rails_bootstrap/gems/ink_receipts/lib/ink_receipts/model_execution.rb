module InkReceipts
  class << self
    def issue_model_execution(payload:, parents: [], issuer:, signer:)
      Client.new.issue_agevidence(
        payload: payload,
        receipt_type: "model_execution_receipt",
        schema: "athian.agevidence.model_execution.v1",
        parents: parents,
        issuer: issuer,
        signer: signer
      )
    end
  end
end
