require "test_helper"

class EvidenceInstrumentHelperTest < ActionView::TestCase
  test "status tone maps evidence semantics" do
    assert_equal "valid", ei_status_tone("valid")
    assert_equal "human_review", ei_status_tone("eligible_with_conditions")
    assert_equal "material_gap", ei_status_tone("insufficient_evidence")
    assert_equal "sealed", ei_status_tone("sealed")
    assert_equal "unverified", ei_status_tone("unknown")
  end

  test "shared status partial renders namespaced classes" do
    html = ei_status("Human review", status: "eligible_with_conditions")

    assert_includes html, "ei-status"
    assert_includes html, "ei-status--human_review"
    assert_includes html, "Human review"
  end
end
