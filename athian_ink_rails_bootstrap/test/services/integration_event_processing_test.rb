require "test_helper"

class IntegrationEventProcessingTest < ActiveSupport::TestCase
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

  test "source manifest handler writes projection and deterministic outbox" do
    project = create_project_mapping
    event = create_event(
      event_id: "evt_source_manifest",
      event_type: "source.manifest_available",
      subject_type: "source_manifest",
      subject_id: "manifest-test",
      data: {
        "manifest_id" => "manifest-test",
        "project_id" => "project-test",
        "source_systems" => ["supplier_erp"],
        "objects" => [{ "document_id" => "invoice-test", "digest" => "sha256:invoice" }],
        "object_digests" => ["sha256:invoice"],
        "retention_policy" => "controlled_7_year",
        "access_references" => ["evidence://invoice-test"],
        "data_classification" => "restricted"
      }
    )

    assert_difference "EvidenceProjection.count", 1 do
      assert_difference "ReceiptOutbox.count", 1 do
        Integrations::EventProcessor.new(event: event).call
      end
    end

    outbox = ReceiptOutbox.last
    assert_equal "source_manifest_receipt", outbox.receipt_type
    assert_match "evt_source_manifest", outbox.idempotency_key
    assert_equal project.id, outbox.canonical_payload_json.fetch("project_internal_id")
  end

  test "receipt outbox processor issues one receipt for one idempotency key" do
    create_project_mapping
    event = create_event(
      event_id: "evt_intervention",
      event_type: "intervention.recorded",
      subject_type: "intervention",
      subject_id: "intervention-test",
      data: {
        "intervention_id" => "intervention-test",
        "project_id" => "project-test",
        "product_id" => "product-test",
        "animal_or_herd_reference" => "cohort-test",
        "delivery_or_administration_date" => "2026-07-12",
        "dose_or_quantity" => "10.000",
        "unit" => "kg",
        "source_manifest_id" => "manifest-test"
      }
    )
    Integrations::EventProcessor.new(event: event).call
    outbox = ReceiptOutbox.last

    assert_difference "Receipt.count", 1 do
      Agevidence::ReceiptOutboxProcessor.new(receipt_outbox: outbox).call
    end

    assert_equal "verified", outbox.reload.status
    assert_no_difference "Receipt.count" do
      Agevidence::ReceiptOutboxProcessor.new(receipt_outbox: outbox).call
    end
  end

  private

  def create_project_mapping
    account = Agevidence::DeveloperAccount.create!(name: "Synthetic Producer", status: "synthetic_demo")
    project = account.developer_projects.create!(
      name: "Project Test",
      project_type: "intervention",
      integration_status: "source_registered",
      protocol_status: "mapping"
    )
    ExternalObjectMapping.create!(
      integration_source: @source,
      external_object_type: "project",
      external_object_id: "project-test",
      internal_record_type: "Agevidence::DeveloperProject",
      internal_record_id: project.id,
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    project
  end

  def create_event(event_id:, event_type:, subject_type:, subject_id:, data:)
    payload = {
      "event_id" => event_id,
      "event_type" => event_type,
      "schema_version" => "1.0.0",
      "source" => @source.key,
      "occurred_at" => "2026-08-04T18:00:00Z",
      "subject" => { "type" => subject_type, "external_id" => subject_id },
      "correlation" => { "project_id" => "project-test" },
      "data" => data,
      "integrity" => {
        "payload_digest" => "pending",
        "signature_algorithm" => "hmac-sha256",
        "signature" => "pending"
      }
    }
    canonical = InkReceipts.canonicalize_integration_event(payload)
    payload["integrity"]["payload_digest"] = InkReceipts.integration_payload_digest(canonical)
    payload["integrity"]["signature"] = InkReceipts.sign_integration_payload(secret: @source.verification_secret, timestamp: payload.fetch("occurred_at"), canonical_payload: canonical)

    event = @source.integration_events.create!(
      external_event_id: event_id,
      event_type: event_type,
      schema_version: "1.0.0",
      external_object_type: subject_type,
      external_object_id: subject_id,
      occurred_at: Time.zone.parse(payload.fetch("occurred_at")),
      received_at: Time.current,
      raw_payload_json: JSON.generate(payload),
      canonical_payload_json: canonical,
      payload_digest: payload.dig("integrity", "payload_digest"),
      provided_digest: payload.dig("integrity", "payload_digest"),
      signature: payload.dig("integrity", "signature"),
      signature_algorithm: payload.dig("integrity", "signature_algorithm"),
      signature_status: "valid",
      schema_status: "valid",
      processing_status: "accepted",
      correlation_json: payload.fetch("correlation")
    )
    event.integration_operations.create!(
      operation_type: "event_processing",
      status: "pending",
      idempotency_key: "integration-event:#{@source.key}:#{event_id}"
    )
    event
  end
end
