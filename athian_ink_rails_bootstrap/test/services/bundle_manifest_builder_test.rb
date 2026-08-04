require "test_helper"

class BundleManifestBuilderTest < ActiveSupport::TestCase
  test "includes explicit trust limitations" do
    avsa = create_demo_avsa(protocol: create_demo_protocol(code: "B-1"), external_id: "B-A-1")
    create_demo_receipt(avsa: avsa, receipt_type: "issuance_receipt", title: "Issuance Receipt")

    manifest = BundleManifestBuilder.new(avsa: avsa, bundle_type: "buyer").call

    assert_equal "Buyer Evidence Bundle", manifest[:bundle_name]
    assert manifest[:limitations].any? { |line| line.include?("trust boundary") }
  end
end
