module InkReceipts
  class << self
    def issue_review_decision(payload:, parents: [], issuer:, signer:)
      Client.new.issue_agevidence(
        payload: payload,
        receipt_type: "human_review_receipt",
        schema: "athian.agevidence.human_review.v1",
        parents: parents,
        issuer: issuer,
        signer: signer
      )
    end
  end
end
