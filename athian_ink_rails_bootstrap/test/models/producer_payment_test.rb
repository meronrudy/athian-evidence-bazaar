require "test_helper"

class ProducerPaymentTest < ActiveSupport::TestCase
  setup do
    @avsa = create_demo_avsa(protocol: create_demo_protocol(code: "P-1"), external_id: "PAY-1")
  end

  test "requires net amount to reconcile" do
    payment = ProducerPayment.new(
      avsa: @avsa,
      producer_name: "Producer",
      gross_amount: 100,
      verification_deduction: 10,
      platform_deduction: 15,
      other_deductions: 0,
      net_amount: 70,
      currency: "USD",
      status: "pending"
    )

    assert_not payment.valid?
    assert_includes payment.errors[:net_amount], "must equal gross amount minus deductions"
  end
end
