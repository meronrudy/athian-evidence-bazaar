require "test_helper"

class Commercial::Orders::AuthorizeTest < ActiveSupport::TestCase
  setup do
    @project = agevidence_developer_projects(:one)
    @quote = agevidence_pricing_quotes(:one)
    @order = Commercial::Orders::Create.call(@project, @quote)
  end

  test "authorizes order from quoted status" do
    order = Commercial::Orders::Authorize.call(@order)

    assert_equal "checkout_pending", order.status
  end

  test "authorizes order from checkout_pending status" do
    Commercial::Orders::Authorize.call(@order)
    order = Commercial::Orders::Authorize.call(@order)

    assert_equal "checkout_pending", order.status
  end

  test "records authorize event" do
    order = Commercial::Orders::Authorize.call(@order)

    event = Commercial::OrderEvent.for_order(order).last
    assert_equal "authorize", event.event_type
    assert_equal "quoted", event.from_state
    assert_equal "checkout_pending", event.to_state
  end

  test "does not authorize from paid status" do
    Commercial::Orders::MarkPaid.call(@order)
    assert_raises(RuntimeError) do
      Commercial::Orders::Authorize.call(@order)
    end
  end

  test "does not authorize from assembling status" do
    Commercial::Orders::BeginFulfillment.call(@order)
    assert_raises(RuntimeError) do
      Commercial::Orders::Authorize.call(@order)
    end
  end
end