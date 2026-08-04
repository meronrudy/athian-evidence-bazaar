require "test_helper"

class ClaimGroupTest < ActiveSupport::TestCase
  setup do
    avsa = create_demo_avsa(protocol: create_demo_protocol(code: "C-1"), external_id: "C-A-1")
    @group = avsa.create_claim_group!(name: "Group", verified_total: 100, unit: "tCO2e", aggregate_cap_percent: 100)
  end

  test "accepts shares at the aggregate cap" do
    @group.claim_shares.build(claimant_name: "A", claimant_role: "Buyer", share_percent: 60, contribution_amount: 1)
    @group.claim_shares.build(claimant_name: "B", claimant_role: "Buyer", share_percent: 40, contribution_amount: 1)

    assert @group.valid?
    assert_equal BigDecimal("100"), @group.claimed_percent
  end

  test "rejects shares above the aggregate cap" do
    @group.claim_shares.build(claimant_name: "A", claimant_role: "Buyer", share_percent: 70, contribution_amount: 1)
    @group.claim_shares.build(claimant_name: "B", claimant_role: "Buyer", share_percent: 40, contribution_amount: 1)

    assert_not @group.valid?
    assert_includes @group.errors.full_messages.join, "Aggregate claim shares"
  end

  test "rejects duplicate claimants" do
    @group.claim_shares.build(claimant_name: "A", claimant_role: "Buyer", share_percent: 60, contribution_amount: 1)
    @group.claim_shares.build(claimant_name: "A", claimant_role: "Buyer", share_percent: 40, contribution_amount: 1)

    assert_not @group.valid?
    assert_includes @group.errors.full_messages.join, "Duplicate claimant"
  end
end
