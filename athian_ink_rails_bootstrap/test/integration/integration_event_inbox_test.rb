require "test_helper"

class IntegrationEventInboxTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @source = IntegrationSource.create!(
      key: "athian_salesforce_production",
      name: "Athian Salesforce",
      environment: "test",
      signature_algorithm: "hmac_sha256",
      verification_secret_ciphertext: "test-secret",
      allowed_event_types: Integrations::EventRegistry::EVENT_TYPES.keys
    )
  end

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "valid signed event is accepted asynchronously" do
    body = JSON.generate(signed_event(project_registered_payload))

    assert_difference "IntegrationEvent.count", 1 do
      post v1_integrations_events_path, params: body, headers: integration_headers(body)
    end

    assert_response :accepted
    payload = JSON.parse(response.body)
    assert_equal "evt_project_4030_test_01", payload.fetch("event_id")
    assert_equal false, payload.fetch("duplicate")
    assert_match(/\Aop_/, payload.fetch("operation_id"))
    assert_equal "accepted", IntegrationEvent.last.processing_status
  end

  test "duplicate event with same payload returns original operation" do
    body = JSON.generate(signed_event(project_registered_payload))
    post v1_integrations_events_path, params: body, headers: integration_headers(body)
    first_operation = JSON.parse(response.body).fetch("operation_id")

    assert_no_difference "IntegrationEvent.count" do
      post v1_integrations_events_path, params: body, headers: integration_headers(body)
    end

    assert_response :accepted
    payload = JSON.parse(response.body)
    assert_equal true, payload.fetch("duplicate")
    assert_equal first_operation, payload.fetch("operation_id")
  end

  test "duplicate event with different payload is rejected" do
    body = JSON.generate(signed_event(project_registered_payload))
    post v1_integrations_events_path, params: body, headers: integration_headers(body)

    changed = project_registered_payload
    changed["data"]["project_name"] = "Changed Project"
    changed_body = JSON.generate(signed_event(changed))

    assert_no_difference "IntegrationEvent.count" do
      post v1_integrations_events_path, params: changed_body, headers: integration_headers(changed_body)
    end

    assert_response :conflict
    assert_equal "EVENT_ID_PAYLOAD_CONFLICT", JSON.parse(response.body).dig("error", "code")
  end

  test "invalid signature is rejected and retained" do
    event = signed_event(project_registered_payload.merge("event_id" => "evt_project_4030_bad_sig"))
    event["integrity"]["signature"] = "v1=bad"
    body = JSON.generate(event)

    assert_difference "IntegrationEvent.count", 1 do
      post v1_integrations_events_path, params: body, headers: integration_headers(body, signature: "v1=bad")
    end

    assert_response :unauthorized
    assert_equal "signature_invalid", IntegrationEvent.last.processing_status
  end

  test "unknown event type is retained and ignored" do
    event = project_registered_payload.merge(
      "event_id" => "evt_project_4030_unknown",
      "event_type" => "custom.future_event"
    )
    body = JSON.generate(signed_event(event))

    post v1_integrations_events_path, params: body, headers: integration_headers(body)

    assert_response :accepted
    assert_equal "ignored_unknown_type", IntegrationEvent.last.processing_status
    assert_equal "unknown_event_type", IntegrationEvent.last.schema_status
  end

  test "processing project event creates mapping and projection" do
    body = JSON.generate(signed_event(project_registered_payload))

    perform_enqueued_jobs do
      post v1_integrations_events_path, params: body, headers: integration_headers(body)
    end

    event = IntegrationEvent.last
    assert_equal "processed", event.processing_status
    assert_equal "succeeded", event.current_operation.status
    assert_equal 1, Agevidence::DeveloperProject.count
    assert_equal 1, ExternalObjectMapping.where(external_object_type: "project").count
    assert_equal 1, EvidenceProjection.where(projection_type: "project", current_state: "complete").count
  end

  private

  def project_registered_payload
    {
      "event_id" => "evt_project_4030_test_01",
      "event_type" => "project.registered",
      "schema_version" => "1.0.0",
      "source" => @source.key,
      "occurred_at" => "2026-08-04T18:00:00Z",
      "subject" => { "type" => "project", "external_id" => "project-4030-test" },
      "correlation" => { "project_id" => "project-4030-test" },
      "data" => {
        "project_id" => "project-4030-test",
        "project_name" => "Project 4030 Test",
        "producer_id" => "producer-4030-test",
        "producer_name" => "Synthetic Producer",
        "facility_or_farm_id" => "facility-test",
        "country_code" => "AU",
        "monitoring_period_start" => "2026-07-01",
        "monitoring_period_end" => "2026-12-31",
        "current_status" => "registered"
      },
      "integrity" => {
        "payload_digest" => "pending",
        "signature_algorithm" => "hmac-sha256",
        "signature" => "pending"
      }
    }
  end

  def signed_event(payload)
    canonical = InkReceipts.canonicalize_integration_event(payload)
    payload["integrity"]["payload_digest"] = InkReceipts.integration_payload_digest(canonical)
    payload["integrity"]["signature"] = InkReceipts.sign_integration_payload(
      secret: @source.verification_secret,
      timestamp: payload.fetch("occurred_at"),
      canonical_payload: canonical
    )
    payload
  end

  def integration_headers(body, signature: nil)
    parsed = JSON.parse(body)
    {
      "CONTENT_TYPE" => "application/json",
      "X-Athian-Integration-Source" => @source.key,
      "X-Athian-Event-Id" => parsed.fetch("event_id"),
      "X-Athian-Timestamp" => parsed.fetch("occurred_at"),
      "X-Athian-Signature" => signature || parsed.dig("integrity", "signature")
    }
  end
end
