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
end
