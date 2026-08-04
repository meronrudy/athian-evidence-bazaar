require "test_helper"

class TrustBoundaryTest < ActiveSupport::TestCase
  test "rails app and seed code do not perform direct cryptography" do
    files = Dir[
      Rails.root.join("app/**/*.{rb,js,erb}"),
      Rails.root.join("db/**/*.rb")
    ]
    source = files.map { |path| File.read(path) }.join("\n")

    assert_no_match(/\bDigest\b/, source)
    assert_no_match(/\bOpenSSL\b/, source)
    assert_no_match(/crypto\.subtle\.digest/, source)
    assert_no_match(/SHA256|SHA-256/, source)
  end

  test "country method rules stay out of rails controllers and templates" do
    files = Dir[
      Rails.root.join("app/controllers/**/*.{rb}"),
      Rails.root.join("app/views/**/*.erb")
    ]
    source = files.map { |path| File.read(path) }.join("\n")

    assert_no_match(/CA-FED|J-Credit|canada_federal|j_credit|brazil_car|eu_crcf/i, source)
  end

  test "generic rust crates do not depend on country adapters" do
    root = Rails.root.dirname
    files = %w[
      baink-core
      baink-schema
      baink-canonical
      baink-crypto
      baink-bundle
      baink-verify
    ].flat_map { |crate| Dir[root.join("crates/#{crate}/src/**/*.rs")] }
    source = files.map { |path| File.read(path) }.join("\n")

    assert_no_match(/baink_agevidence|country_adapter|country_determination/i, source)
  end
end
