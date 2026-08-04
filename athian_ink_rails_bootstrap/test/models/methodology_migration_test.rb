require "test_helper"

class MethodologyMigrationTest < ActiveSupport::TestCase
  test "records methodology changes as append-only projections" do
    avsa = create_demo_avsa(protocol: create_demo_protocol(code: "M-1"), external_id: "M-A-1")
    receipt = create_demo_receipt(avsa: avsa, receipt_type: "methodology_delta_receipt", title: "Methodology Delta Receipt")

    migration = avsa.methodology_migrations.create!(
      delta_receipt: receipt,
      old_methodology: "VM0042",
      old_version: "v2.2",
      new_methodology: "VM0042",
      new_version: "v3.0",
      status: "appended",
      affected_credits: 100,
      impact_summary: "Historical chain preserved",
      recalculation_payload: { impact: "Historical chain preserved" },
      appended_at: Time.current
    )

    assert_equal receipt, migration.delta_receipt
    assert_equal "VM0042 v2.2 -> VM0042 v3.0", migration.transition_label
  end
end
