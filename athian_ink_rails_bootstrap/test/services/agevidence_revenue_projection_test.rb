require "test_helper"

class AgevidenceRevenueProjectionTest < ActiveSupport::TestCase
  test "base revenue totals match management scenario" do
    projection = Agevidence::RevenueProjection.from_config

    assert_equal 322_000_000, projection.base_totals.fetch("y1")
    assert_equal 769_000_000, projection.base_totals.fetch("y2")
    assert_equal 1_497_000_000, projection.base_totals.fetch("y3")
  end

  test "recurring component matches required base outputs" do
    projection = Agevidence::RevenueProjection.from_config

    assert_equal 180_000_000, projection.recurring_totals.fetch("y1")
    assert_equal 450_000_000, projection.recurring_totals.fetch("y2")
    assert_equal 860_000_000, projection.recurring_totals.fetch("y3")
  end
end
