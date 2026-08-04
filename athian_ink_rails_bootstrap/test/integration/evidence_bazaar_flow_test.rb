require "test_helper"

class EvidenceBazaarFlowTest < ActionDispatch::IntegrationTest
  setup do
    @avsa = create_demo_avsa(protocol: create_demo_protocol(code: "I-1"), external_id: "I-A-1")
    parent = nil
    InkProjection::CORE_RECEIPT_TYPES.each_with_index do |type, index|
      parent = create_demo_receipt(
        avsa: @avsa,
        receipt_type: type,
        title: type.humanize,
        sequence: index + 1,
        parents: [parent].compact
      )
    end
  end

  test "dashboard renders evidence-first operating model" do
    get root_path

    assert_response :success
    assert_select "h1", /Evidence first/
    assert_select "td", text: /Portable Proof Product/
  end

  test "avsa chain renders seven core receipt nodes" do
    get avsa_path(@avsa)

    assert_response :success
    assert_select ".receipt-node", 7
  end
end
