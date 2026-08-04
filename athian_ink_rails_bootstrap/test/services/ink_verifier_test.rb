require "test_helper"

class InkVerifierTest < ActiveSupport::TestCase
  setup do
    @avsa = create_demo_avsa(protocol: create_demo_protocol(code: "V-1"), external_id: "V-A-1")
    @avsa.update!(root_digest: "abc")
  end

  test "returns indeterminate when terminal state is unavailable" do
    create_demo_receipt(avsa: @avsa, receipt_type: "practice_receipt", title: "Practice Receipt", lifecycle_state: "observed", integrity_status: "indeterminate")

    result = InkVerifier.new(target: @avsa).call

    assert_equal "indeterminate", result[:status]
    assert_equal "ink_receipts", result[:mode]
  end
end
