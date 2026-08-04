require "test_helper"

class InkReceiptsFacadeTest < ActiveSupport::TestCase
  test "issues receipt projections behind the facade" do
    issued = InkReceipts.issue(
      payload: { example: "payload" },
      issuer: "Athian Test",
      receipt_type: "practice_receipt",
      schema: "athian.practice_receipt.v1"
    )

    assert_equal "practice_receipt", issued.fetch(:receipt_type)
    assert issued.fetch(:body_digest).present?
    assert issued.fetch(:canonical_encoding_hex).present?
  end

  test "previews command construction" do
    command = InkReceipts.command_preview("verify", "bundle.json")

    assert_includes command, "verify"
    assert_includes command, "bundle.json"
  end

  test "bundle verification separates cryptographic and external status" do
    report = InkReceipts.verify_bundle(
      manifest: {
        receipts: [
          {
            sequence: 1,
            receipt_type: "practice_receipt",
            evidence: [
              { name: "Invoice", status: "present" }
            ]
          }
        ]
      }
    )

    assert_equal "valid", report.fetch(:cryptographic_status)
    assert_equal "indeterminate", report.fetch(:external_status)
  end
end
