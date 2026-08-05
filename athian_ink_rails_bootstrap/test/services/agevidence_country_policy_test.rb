require "test_helper"

class AgevidenceCountryPolicyTest < ActiveSupport::TestCase
  setup do
    @protocol = create_demo_protocol(code: "AGEV-COUNTRY")
    @avsa = create_demo_avsa(protocol: @protocol, external_id: "AGEV-COUNTRY-A")
    @receipt = create_demo_receipt(avsa: @avsa, receipt_type: "model_execution_receipt", title: "Model Execution")
    %w[
      evidence.animal_cohort
      evidence.intervention_delivery
      evidence.feed_record
      evidence.weight_record
      evidence.baseline_ration
    ].each_with_index do |global_type, index|
      @receipt.evidence_items.create!(
        name: "Source #{index + 1}",
        evidence_type: global_type.split(".").last,
        source_system: "test",
        commitment: "sha256:source-#{index}",
        disclosure_status: "restricted",
        status: "present",
        metadata: {
          document_id: "source-#{index}",
          global_evidence_type: global_type
        }
      )
    end

    @account = Agevidence::DeveloperAccount.create!(
      name: "Country Test Startup",
      funding_stage: "Series A",
      capital_raised_cents: 1_000_000,
      primary_segment: "Livestock methane",
      status: "active"
    )
    @country_adapters = Agevidence::CountryAdapterCatalog.sync!
    @canada_adapter = @country_adapters.detect { |adapter| adapter.adapter_id == "athian-country-ca-beef-v1" }
    @australia_adapter = @country_adapters.detect { |adapter| adapter.adapter_id == "athian-country-au-livestock-v1" }
    @project = @account.developer_projects.create!(
      protocol: @protocol,
      avsa: @avsa,
      country_program: @canada_adapter.country_program,
      primary_country_program: @canada_adapter.country_program,
      name: "Global Graph Pilot",
      project_type: "intervention",
      target_claim: "The intervention reduces enteric methane.",
      protocol_status: "mapping",
      integration_status: "source_registered",
      country_context: {
        species: "species.beef_cattle",
        production_system: "production.confined_feeding",
        intervention_class: "intervention.ration_reformulation"
      }
    )
  end

  test "country adapter catalog loads uniform manifests" do
    manifests = Agevidence::CountryAdapterCatalog.manifests

    assert_operator manifests.size, :>=, 8
    manifests.each do |manifest|
      assert_equal "ink.receipt.v2", manifest.fetch("global_contract").fetch("receipt_envelope")
      assert manifest.fetch("required_evidence").is_a?(Array)
      assert manifest.fetch("limitations").any?
    end

    reports = manifests.map { |manifest| Agevidence::CountryAdapterCatalog.validation_report(manifest) }
    assert_equal "active", reports.detect { |report| report.fetch("country_code") == "AU" }.fetch("classification")
    assert_equal "active", reports.detect { |report| report.fetch("country_code") == "CA" }.fetch("classification")
    assert_equal "scaffold", reports.detect { |report| report.fetch("country_code") == "NZ" }.fetch("classification")
    assert_equal "research", reports.detect { |report| report.fetch("country_code") == "UK" }.fetch("classification")
    assert reports.all? { |report| report.fetch("manifest_path").is_a?(String) }
  end

  test "country adapter catalog sync updates existing projections" do
    @canada_adapter.update!(status: "scaffold")
    @canada_adapter.country_method_version.update!(status: "scaffold")

    synced = Agevidence::CountryAdapterCatalog.sync!.detect { |adapter| adapter.adapter_id == "athian-country-ca-beef-v1" }

    assert_equal "active", synced.status
    assert_equal "active", synced.country_method_version.status
  end

  test "artifact profiles are loaded from country adapter packs" do
    profile = Agevidence::CountryAdapterCatalog.artifact_profile(@canada_adapter, "ca-federal-submission-v1")

    assert_equal "ca-federal-submission-v1", profile.fetch("profile").fetch("id")
    assert_includes profile.fetch("required_receipts"), "country_compatibility_determination_receipt"
    assert profile.fetch("verification").fetch("local_verifier_required")
  end

  test "eligibility evaluator returns one country-neutral determination shape" do
    result = Agevidence::CountryEligibilityEvaluator.new(project: @project, country_adapter: @canada_adapter).call

    assert_equal "athian.country_determination.v1", result.fetch("contract")
    assert_equal "CA", result.fetch("country_code")
    assert_equal "eligible_with_conditions", result.fetch("status")
    assert_includes result.fetch("missing_evidence"), "evidence.baseline_performance"
    assert_equal "Athian compatibility assessment only", result.fetch("determination_role")
    assert result.key?("policy_extensions")
    assert result.key?("policy_stack")
    assert result.key?("identifier_bindings")
    assert result.key?("external_checks")
    assert result.key?("source_profile_versions")
    assert result.key?("supersedes")
    assert result.key?("registry_mapping")
  end

  test "policy stack resolver surfaces institution conflicts" do
    result = Agevidence::PolicyStackResolver.new(
      country_adapter: @canada_adapter,
      institution_profile: {
        "profile_type" => "buyer",
        "profile_id" => "buyer-conflict-v1",
        "requirements" => ["evidence.verification_readiness_report"],
        "conflicts" => ["evidence.rights_receipt"]
      }
    ).call

    assert_includes result.fetch("unresolved_conflicts"), "evidence.rights_receipt"
    assert result.fetch("results").any? { |item| item.fetch("code") == "unresolved_conflict" }
    assert result.fetch("results").any? { |item| item.fetch("code") == "institution_specific_requirement" }
  end

  test "same evidence graph can be evaluated through multiple adapters" do
    root_before = @project.evidence_graph_root
    canada = Agevidence::CountryEligibilityEvaluator.new(project: @project, country_adapter: @canada_adapter).call
    australia = Agevidence::CountryEligibilityEvaluator.new(project: @project, country_adapter: @australia_adapter).call

    assert_equal root_before, @project.evidence_graph_root
    assert_equal "CA", canada.fetch("country_code")
    assert_equal "AU", australia.fetch("country_code")
    assert_not_equal canada.fetch("adapter_id"), australia.fetch("adapter_id")
    assert_equal canada.keys.sort, australia.keys.sort
  end

  test "country determinations are appended with commitment receipts" do
    determination = Agevidence::CountryDeterminationAppender.new(project: @project, country_adapter: @canada_adapter).call

    assert_equal "eligible_with_conditions", determination.status
    assert_equal "country_compatibility_determination_receipt", determination.receipt.receipt_type
    assert_equal "country_adapter_commitment_receipt", @canada_adapter.reload.commitment_receipt.receipt_type
    assert_equal determination.receipt.parent_receipt_ids.uniq, determination.receipt.parent_receipt_ids
    assert_includes determination.receipt.parent_receipt_ids, @receipt.id
    assert_includes determination.receipt.parent_receipt_ids, @canada_adapter.commitment_receipt.id
    assert_not determination.update(status: "eligible")
  end

  test "artifact assembly binds bundle to latest country determination profile" do
    determination = Agevidence::CountryDeterminationAppender.new(project: @project, country_adapter: @canada_adapter).call
    product = Agevidence::ProductCatalog.fetch("verification_readiness_cycle")
    engagement = @project.artifact_engagements.create!(
      product_code: "verification_readiness_cycle",
      pipeline_stage: "scoped",
      billing_type: product.fetch("billing_type"),
      list_price_cents: product.fetch("base_planning_price_cents"),
      quoted_price_cents: product.fetch("base_planning_price_cents"),
      currency: "USD",
      commercial_status: "proposed"
    )

    bundle = Agevidence::ArtifactAssembler.new(engagement: engagement).call

    assert_equal determination, bundle.country_determination
    assert_equal @canada_adapter, bundle.country_adapter
    artifact_profile = bundle.manifest[:artifact_profile] || bundle.manifest["artifact_profile"]
    assert_equal "ca-method-compatibility-v1", artifact_profile.dig("profile", "id")
  end
end
