require "test_helper"

class AgevidenceScaffoldTest < ActiveSupport::TestCase
  setup do
    @protocol = create_demo_protocol(code: "AGEV-1")
    @avsa = create_demo_avsa(protocol: @protocol, external_id: "AGEV-A-1")
    @receipt = create_demo_receipt(avsa: @avsa, receipt_type: "model_execution_receipt", title: "Model Execution")
    @receipt.evidence_items.create!(
      name: "Trial Report",
      evidence_type: "trial_report",
      source_system: "test",
      commitment: "sha256:test-source",
      disclosure_status: "restricted",
      status: "present",
      metadata: { document_id: "trial-report-001" }
    )
    @account = Agevidence::DeveloperAccount.create!(
      name: "Test Startup",
      funding_stage: "Seed",
      capital_raised_cents: 100_000,
      primary_segment: "Intervention",
      status: "active"
    )
    @project = @account.developer_projects.create!(
      protocol: @protocol,
      avsa: @avsa,
      name: "Methane Pilot",
      project_type: "intervention",
      target_claim: "The intervention reduces methane.",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
    @adapter = Agevidence::ModelAdapter.create!(
      adapter_id: "qwen3.5-4b-reference-test",
      base_model_id: "Qwen/Qwen3.5-4B",
      license: "reference",
      runtime: "fixture",
      weights_digest: "sha256:weights",
      adapter_digest: "sha256:adapter",
      status: "reference"
    )
  end

  test "ingests fixture model run candidates and gaps" do
    run = Agevidence::ModelRunIngestion.new(project: @project, model_adapter: @adapter).call

    assert_equal "completed", run.status
    assert_equal 7, run.evidence_candidates.count
    assert_equal 3, run.evidence_gaps.count
    assert_equal "model_ready", @project.reload.integration_status
  end

  test "review decisions are append-only" do
    run = Agevidence::ModelRunIngestion.new(project: @project, model_adapter: @adapter).call
    candidate = run.evidence_candidates.first
    decision = candidate.review_decisions.create!(
      reviewer_role: "Reviewer",
      decision: "accepted",
      reason: "Source linked",
      policy_version: "ATH-AGEV-POLICY-v1",
      decided_at: Time.current
    )

    assert_equal "accepted", candidate.reload.review_status
    assert_not decision.update(reason: "Changed")
  end

  test "artifact engagement and reliance event update bundle status" do
    engagement = @project.artifact_engagements.create!(
      product_code: "verification_readiness_cycle",
      pipeline_stage: "assembled",
      billing_type: "fixed_fee",
      list_price_cents: 60_000,
      quoted_price_cents: 60_000,
      currency: "USD",
      commercial_status: "illustrative"
    )
    bundle = @avsa.evidence_bundles.create!(
      bundle_type: "auditor",
      name: "Verification Readiness Cycle",
      status: "generated",
      artifact_filename: "test.zip",
      verification_status: "valid",
      manifest: { artifact_digest: "sha256:artifact" },
      generated_at: Time.current,
      commercial_product_code: engagement.product_code,
      artifact_version: "v1"
    )
    engagement.update!(evidence_bundle: bundle)

    engagement.reliance_events.create!(
      evidence_bundle: bundle,
      relying_party_name: "Synthetic VVB",
      relying_party_role: "vvb",
      decision_type: "readiness",
      outcome: "relied_on",
      evidence_bundle_digest: bundle.evidence_bundle_digest,
      occurred_at: Time.current
    )

    assert_equal "relied_on", bundle.reload.reliance_status
    assert_equal 1, bundle.relying_party_count
  end
end
