require "test_helper"

class CountryEligibilityEvaluatorTest < ActiveSupport::TestCase
  setup do
    @program = Agevidence::CountryProgram.create!(
      code: "CA",
      country_name: "Canada",
      program_name: "Canada Federal Beef Evidence Adapter",
      priority: 1,
      phase: "method_ready",
      status: "active",
      currency: "CAD",
      market_condition: "Bounded federal method.",
      developer_proposition: "Turn feedlot data into protocol-ready evidence."
    )
    method = @program.country_methods.create!(
      code: "CA-FED-REME-BC",
      name: "Reducing Enteric Methane Emissions from Beef Cattle",
      authority: "Government of Canada federal offset system",
      scope: "Confined beef feeding operations.",
      status: "active"
    )
    @version = method.country_method_versions.create!(version: "v1.0", status: "active")
    @program.country_adapters.create!(
      country_method_version: @version,
      adapter_id: "athian-country-ca-beef-v1",
      version: "v1",
      status: "active",
      eligibility_rules: {
        "eligible_activity" => "confined beef feeding operation",
        "required_evidence" => %w[animal_cohort baseline_ration],
        "excluded_contexts" => %w[dairy_cattle grazing],
        "allowed_contexts" => {
          "species" => ["beef_cattle"],
          "production_system" => ["confined_beef_feeding"]
        }
      }
    )
    @account = Agevidence::DeveloperAccount.create!(name: "Test Developer", status: "synthetic_demo")
  end

  test "returns eligible with conditions when method applies but evidence is missing" do
    project = @account.developer_projects.create!(
      country_program: @program,
      name: "Feedlot Pilot",
      project_type: "intervention",
      protocol_status: "aligned",
      integration_status: "source_registered",
      country_context: {
        "species" => "beef_cattle",
        "production_system" => "confined_beef_feeding"
      }
    )

    result = Agevidence::CountryEligibilityEvaluator.new(project: project).call

    assert_equal "eligible_with_conditions", result.fetch(:status)
    assert_equal %w[animal_cohort baseline_ration], result.fetch(:missing_evidence)
    assert_equal "Athian compatibility assessment only", result.fetch(:determination_role)
  end

  test "returns outside current method for an excluded production context" do
    project = @account.developer_projects.create!(
      country_program: @program,
      name: "Dairy Pilot",
      project_type: "intervention",
      protocol_status: "mapping",
      integration_status: "not_started",
      country_context: {
        "species" => "dairy_cattle",
        "production_system" => "confined_dairy"
      }
    )

    result = Agevidence::CountryEligibilityEvaluator.new(project: project).call

    assert_equal "outside_current_method", result.fetch(:status)
    assert_includes result.fetch(:excluded_contexts), "dairy_cattle"
  end

  test "returns unassigned without a country program" do
    project = @account.developer_projects.create!(
      name: "Global Project",
      project_type: "platform",
      protocol_status: "mapping",
      integration_status: "not_started"
    )

    result = Agevidence::CountryEligibilityEvaluator.new(project: project).call

    assert_equal "unassigned", result.fetch(:status)
  end
end
