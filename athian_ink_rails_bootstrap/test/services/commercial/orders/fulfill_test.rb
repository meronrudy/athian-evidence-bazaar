require "test_helper"

class Commercial::Orders::FulfillTest < ActiveSupport::TestCase
  setup do
    @project = agevidence_developer_projects(:one)
    @quote = agevidence_pricing_quotes(:one)
    @order = Commercial::Orders::Create.call(@project, @quote)
    Commercial::Orders::MarkPaid.call(@order)
  end

  test "fulfills assembling order" do
    Commercial::Orders::BeginFulfillment.call(@order)
    Commercial::Orders::Fulfill.call(@order)

    assert_equal "fulfilled", @order.status
    assert @order.fulfilled?
    assert_equal "assembling", @order.previous_status
  end

  test "records fulfill event" do
    Commercial::Orders::BeginFulfillment.call(@order)
    Commercial::Orders::Fulfill.call(@order)

    event = Commercial::OrderEvent.for_order(@order).last
    assert_equal "fulfill", event.event_type
    assert_equal "assembling", event.from_state
    assert_equal "fulfilled", event.to_state
  end

  test "sets assembled_at timestamp" do
    Commercial::Orders::BeginFulfillment.call(@order)
    Commercial::Orders::Fulfill.call(@order)

    assert @order.assembled_at?
    assert @order.assembled_at > Time.current - 10 # Within 10 seconds
  end

  test "updates metadata with receipt root" do
    Commercial::Orders::BeginFulfillment.call(@order)
    Commercial::Orders::Fulfill.call(@order)

    assert @order.metadata_json.key?("receipt_root")
    assert @order.metadata_json["receipt_root"]
  end

  test "updates metadata with verification command" do
    Commercial::Orders::BeginFulfillment.call(@order)
    Commercial::Orders::Fulfill.call(@order)

    assert @order.metadata_json.key?("verification_command")
    assert @order.metadata_json["verification_command"]
  end

  test "raises on non-assembling order" do
    Commercial::Orders::MarkPaid.call(@order)
    assert_raises(RuntimeError) do
      Commercial::Orders::Fulfill.call(@order)
    end
  end
end