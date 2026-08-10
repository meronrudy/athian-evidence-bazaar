require 'test_helper'

class ApiKeyTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "api-key-test-#{SecureRandom.alphanumeric(8)}@example.test", name: "API Key Test User")
  end

  test 'api_key generates valid key' do
    api_key = ApiKey.create!(name: 'Test Key', user: @user)
    assert api_key.key.present?
    assert api_key.key.length == 64 # Hex format
  end

  test 'api_key revocation works' do
    api_key = ApiKey.create!(name: 'Test Key', user: @user)
    api_key.revoke!
    assert api_key.revoked_at.present?
    assert_not api_key.active?
  end

  test 'masked key display' do
    api_key = ApiKey.create!(name: 'Test Key', user: @user, key: 'a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890ab')
    assert_equal 'a1b2c3d4...90ab', api_key.masked_key
  end
end
