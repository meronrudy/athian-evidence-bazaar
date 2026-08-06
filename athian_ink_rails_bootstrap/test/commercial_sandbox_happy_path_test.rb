require "test_helper"

class CommercialSandboxHappyPathTest < ActionDispatch::IntegrationTest
  test "commercial sandbox happy path from project to artifact fulfillment" do
    # This test preserves the existing canonical demonstration flow
    # while ensuring all transitions go through the new Commercial layer

    # 1. Create organization (future Phase 1)
    # For now, use existing developer account as compatibility layer
    developer_account = agevidence_developer_accounts(:one)
    project = developer_account.developer_projects.create!(
      external_id: "proj_#{SecureRandom.hex(8)}",
      name: "Commercial Sandbox Test Project"
    )

    # 2. Register source record
    source_record = project.source_records.create!(
      document_id: "doc_#{SecureRandom.hex(8)}",
      source_system: "test_system",
      raw_data: { "type" => "test_evidence" }
    )

    # 3. Model run and review (existing flow)
    model_run = project.model_runs.create!(status: "completed")
    # Simulate review decisions...

    # 4. Quote generation (will use Commercial::Quoting in Phase 3)
    quote = Agevidence::PricingQuote.create!(
      developer_project: project,
      product_code: "verification_readiness",
      amount_cents: 2500000,
      currency: "USD",
      status: "quoted"
    )

    # 5. Order creation via Commercial service (Phase 0)
    order = Commercial::Orders::Create.call(project, quote)

    assert order.persisted?
    assert_equal "quoted", order.status

    # Verify event was recorded
    event = Commercial::OrderEvent.for_order(order).last
    assert_equal "create", event.event_type
    assert_equal "none", event.from_state
    assert_equal "quoted", event.to_state

    # 6. Sandbox checkout using new MarkPaid service (no direct update!)
    Commercial::Orders::MarkPaid.call(order, reason: "Sandbox test payment")

    assert_equal "paid", order.reload.status

    # Verify transition event
    paid_event = Commercial::OrderEvent.for_order(order).last
    assert_equal "mark_paid", paid_event.event_type
    assert_equal "quoted", paid_event.from_state
    assert_equal "paid", paid_event.to_state

    # 7. Begin fulfillment
    Commercial::Orders::BeginFulfillment.call(order)

    assert_equal "assembling", order.reload.status

    # 8. Fulfill
    Commercial::Orders::Fulfill.call(order, reason: "Sandbox artifact ready")

    assert order.fulfilled?
    assert_equal "fulfilled", order.status

    # Final event check
    assert_equal 4, Commercial::OrderEvent.for_order(order).count

    puts "✅ Commercial sandbox happy path test passed with full event ledger"
  end
end
