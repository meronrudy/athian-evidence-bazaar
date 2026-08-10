require 'test_helper'

module Agevidence
  class CountryProgramsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @country_adapter = Agevidence::CountryAdapterCatalog.sync!.detect { |adapter| adapter.adapter_id == "athian-country-ca-beef-v1" }
      @country_program = @country_adapter.country_program
    end

    test "should get country programs index" do
      get agevidence_country_programs_url
      assert_response :success
    end

    test "should get country program detail" do
      get agevidence_country_program_url(@country_program)
      assert_response :success
    end

    test "country program detail renders profile stack" do
      get agevidence_country_program_url(@country_program)
      assert_response :success
      assert_select ".ei-profile-stack"
      assert_select ".ei-stack-layer", minimum: 6
    end

    test "should return 404 for unknown country program" do
      get agevidence_country_program_url(id: 999)
      assert_response :not_found
    end

    test "should get v1 country adapters index" do
      get v1_country_adapters_url
      assert_response :success
    end

    test "should get v1 country adapter detail" do
      get v1_country_adapter_url(@country_adapter.adapter_id)
      assert_response :success
    end
  end
end
