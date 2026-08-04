require "test_helper"

class AgevidenceFlowTest < ActionDispatch::IntegrationTest
  setup do
    protocol = create_demo_protocol(code: "AGEV-I")
    avsa = create_demo_avsa(protocol: protocol, external_id: "AGEV-I-A")
    create_demo_receipt(avsa: avsa, receipt_type: "model_execution_receipt", title: "Model Execution")
    account = Agevidence::DeveloperAccount.create!(
      name: "Northstar Test Systems",
      funding_stage: "Series A",
      capital_raised_cents: 1_800_000_000,
      primary_segment: "Livestock methane",
      status: "synthetic_demo"
    )
    @project = account.developer_projects.create!(
      protocol: protocol,
      avsa: avsa,
      name: "Enterprise Dairy Pilot",
      project_type: "intervention",
      target_claim: "The intervention reduces enteric methane.",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
    @adapter = Agevidence::ModelAdapter.create!(
      adapter_id: "qwen3.5-4b-reference-flow",
      base_model_id: "Qwen/Qwen3.5-4B",
      license: "reference",
      runtime: "fixture",
      weights_digest: "sha256:weights",
      adapter_digest: "sha256:adapter",
      status: "reference"
    )
  end

  test "launchpad renders developer project" do
    get agevidence_root_path

    assert_response :success
    assert_select "h1", /Developer Launchpad/
    assert_select "td", text: /Enterprise Dairy Pilot/
  end

  test "model run can be created from fixture adapter" do
    post agevidence_developer_project_model_runs_path(@project), params: { model_adapter_id: @adapter.id }

    assert_redirected_to agevidence_model_run_path(Agevidence::ModelRun.last)
    follow_redirect!
    assert_select "h1", /qwen3.5/
    assert_select ".list-group-item", minimum: 7
  end
end
