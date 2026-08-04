class InkVerifier
  class VerificationError < StandardError; end

  def initialize(target:)
    @target = target
  end

  def call
    started_at = Time.current
    result = InkReceipts.verify(target: InkProjection.verification_target(target))
    result.merge(started_at: started_at, completed_at: Time.current)
  rescue KeyError, InkReceipts::Error, VerificationError => e
    {
      status: "indeterminate",
      mode: "ink_receipts",
      message: e.message,
      checks: [{ name: "verifier_execution", status: "indeterminate", detail: e.message }],
      started_at: started_at,
      completed_at: Time.current
    }
  end

  private

  attr_reader :target
end
