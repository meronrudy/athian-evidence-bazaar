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
    @country_adapter = Agevidence::CountryAdapterCatalog.sync!.detect { |adapter| adapter.adapter_id == "athian-country-ca-beef-v1" }
    @project.update!(
      country_program: @country_adapter.country_program,
      primary_country_program: @country_adapter.country_program,
      country_context: {
        species: "species.beef_cattle",
        production_system: "production.confined_feeding",
        intervention_class: "intervention.ration_reformulation"
      }
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

  test "country programs render shared thin-waist workflow" do
    get agevidence_country_programs_path

    assert_response :success
    assert_select "h1", /Country Programs/
    assert_select ".alert", /Cryptographic validity, method compatibility, and institutional reliance/

    get agevidence_country_program_path(@country_adapter.country_program)

    assert_response :success
    assert_select "h1", /Government of Canada/
    assert_select "h2", /Evaluate one global evidence graph/
  end

  test "compatibility evaluation appends a country determination" do
    assert_difference "Agevidence::CountryDetermination.count", 1 do
      post evaluate_agevidence_country_program_path(@country_adapter.country_program),
        params: {
          developer_project_id: @project.id,
          country_adapter_id: @country_adapter.id
        }
    end

    assert_redirected_to agevidence_country_program_path(@country_adapter.country_program)
    assert_equal "country_compatibility_determination_receipt", Agevidence::CountryDetermination.last.receipt.receipt_type
  end
end
