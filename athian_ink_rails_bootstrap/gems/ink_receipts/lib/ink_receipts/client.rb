module InkReceipts
  class Client
    def issue_agevidence(payload:, receipt_type:, schema:, parents:, issuer:, signer:, lifecycle: "sealed")
      issue(
        payload: payload,
        issuer: issuer,
        receipt_type: receipt_type,
        schema: schema,
        parents: parents,
        lifecycle: lifecycle,
        signer: signer
      )
    end
  end
end
