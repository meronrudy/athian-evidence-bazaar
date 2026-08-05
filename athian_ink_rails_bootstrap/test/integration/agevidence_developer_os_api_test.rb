require "test_helper"

class AgevidenceDeveloperOsApiTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "developer API creates project, source record, model run, review, quote, order, and artifact" do
    post v1_developer_projects_path,
      params: {
        developer_account: {
          name: "Developer OS API Startup",
          funding_stage: "Seed"
        },
        project: {
          name: "API Methane Pilot",
          external_project_id: "api-project-001",
          target_claim: "The intervention reduces enteric methane."
        }
      }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :created
    project_response = JSON.parse(response.body)
    project_id = project_response.fetch("id")

    perform_enqueued_jobs do
      post v1_developer_project_source_records_path(project_id),
        params: {
          source_record: {
            document_id: "trial-report-001",
            evidence_type: "evidence.animal_cohort",
            controlled_uri: "evidence://trial-report-001",
            commitment: "source:trial-report-001",
            source_system: "developer_api"
          }
        }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }
    end

    assert_response :created
    source_response = JSON.parse(response.body)
    assert_equal "trial-report-001", source_response.fetch("document_id")
    assert_match(/\Aop_/, source_response.fetch("operation_id"))
    assert EvidenceProjection.where(projection_type: "source_manifest").exists?

    post v1_developer_project_model_runs_path(project_id),
      params: { adapter_id: "qwen3.5-4b-reference" }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :created
    run_response = JSON.parse(response.body)
    assert_equal 7, run_response.fetch("candidates").size
    candidate_id = run_response.fetch("candidates").first.fetch("id")

    patch v1_developer_candidate_path(candidate_id),
      params: {
        review_decision: {
          decision: "accepted",
          reason: "Source reference is controlled and reviewable."
        }
      }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :success
    assert_equal "accepted", JSON.parse(response.body).fetch("review_status")

    post v1_pricing_quotes_path,
      params: {
        quote: {
          project_id: project_id,
          product_code: "enterprise_reliance_artifact",
          scope: {
            protocol_complexity: "high",
            evidence_classes: 5,
            source_systems: 2,
            countries: 1,
            relying_parties: 1,
            selective_disclosure: true,
            turnaround_days: 14
          }
        }
      }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :created
    quote_id = JSON.parse(response.body).fetch("quote_id")

    post v1_artifact_orders_path,
      params: { artifact_order: { quote_id: quote_id } }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :created
    order_id = JSON.parse(response.body).fetch("order_id")

    post checkout_v1_artifact_order_path(order_id)
    assert_response :success
    assert_equal "paid", JSON.parse(response.body).fetch("status")

    post v1_developer_project_artifacts_path(project_id),
      params: { order_id: order_id }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :created
    artifact_response = JSON.parse(response.body)
    assert_equal "fulfilled", artifact_response.fetch("status")
    assert_match(/verify-bundle/, artifact_response.dig("artifact", "verification_command"))
  end
end
