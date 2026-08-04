require "test_helper"

class ModelServiceClientCountryTest < ActiveSupport::TestCase
  test "adds country adapter and method context without changing the global model adapter" do
    program = Agevidence::CountryProgram.create!(
      code: "JP",
      country_name: "Japan",
      program_name: "Japan J-Credit Adapter",
      priority: 2,
      phase: "method_ready",
      status: "active",
      currency: "JPY",
      market_condition: "Method-ready market.",
      developer_proposition: "Translate the method into a developer workflow."
    )
    method = program.country_methods.create!(
      code: "JP-JC-LIVESTOCK-FEED",
      name: "J-Credit Feed Method",
      authority: "J-Credit program",
      scope: "Approved livestock feed additives.",
      status: "active"
    )
    version = method.country_method_versions.create!(version: "2026-02", status: "active")
    program.country_adapters.create!(
      country_method_version: version,
      adapter_id: "athian-country-jp-jcredit-feed-v1",
      version: "v1",
      status: "active"
    )
    account = Agevidence::DeveloperAccount.create!(name: "Japan Test Developer", status: "synthetic_demo")
    project = account.developer_projects.create!(
      country_program: program,
      name: "J-Credit Pilot",
      project_type: "platform",
      protocol_status: "mapping",
      integration_status: "not_started",
      target_claim: "Approved additive use is reconstructable."
    )
    model_adapter = Agevidence::ModelAdapter.create!(
      adapter_id: "qwen3.5-4b-reference-test",
      base_model_id: "Qwen/Qwen3.5-4B",
      status: "reference"
    )

    payload = Agevidence::ModelServiceClient.new.request_payload(
      project: project,
      documents: [],
      task: "protocol_evidence_extraction",
      adapter: model_adapter
    )

    assert_equal "qwen3.5-4b-reference-test", payload.fetch(:adapter_id)
    assert_equal "JP", payload.dig(:country, :code)
    assert_equal "athian-country-jp-jcredit-feed-v1", payload.dig(:country, :adapter_id)
    assert_equal "JP-JC-LIVESTOCK-FEED", payload.dig(:country, :method_code)
  end
end
