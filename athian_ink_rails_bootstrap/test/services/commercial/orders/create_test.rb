require "test_helper"

class Commercial::Orders::CreateTest < ActiveSupport::TestCase
  setup do
    @project = agevidence_developer_projects(:one)
    @quote = agevidence_pricing_quotes(:one)
  end

  test "creates order with quoted status" do
    order = Commercial::Orders::Create.call(@project, @quote)

    assert order.persisted?
    assert_equal "quoted", order.status
    assert_equal @project, order.developer_project
    assert_equal @quote, order.pricing_quote
  end

  test "records create event" do
    order = Commercial::Orders::Create.call(@project, @quote)

    event = Commercial::OrderEvent.for_order(order).last
    assert_equal "create", event.event_type
    assert_equal "none", event.from_state
    assert_equal "quoted", event.to_state
    assert_equal "Order created from quote", event.reason
  end

  test "accepts metadata_json" do
    order = Commercial::Orders::Create.call(@project, @quote, metadata_json: { source: "test" })

    assert_equal "test", order.metadata_json["source"]
  end

  test "raises on invalid order" do
    invalid_quote = Agevidence::PricingQuote.new
    assert_raises(ActiveRecord::RecordInvalid) do
      Commercial::Orders::Create.call(@project, invalid_quote)
    end
  end
end