require "test_helper"

class AgevidenceDeveloperOsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @protocol = create_demo_protocol(code: "DEV-OS")
    @avsa = create_demo_avsa(protocol: @protocol, external_id: "DEV-OS-A")
    create_demo_receipt(avsa: @avsa, receipt_type: "model_execution_receipt", title: "Model Execution")
    @account = Agevidence::DeveloperAccount.create!(
      name: "Developer OS Test Startup",
      funding_stage: "Seed",
      primary_segment: "Livestock methane",
      status: "active"
    )
    @project = @account.developer_projects.create!(
      protocol: @protocol,
      avsa: @avsa,
      name: "Developer OS Pilot",
      project_type: "intervention",
      target_claim: "The intervention reduces enteric methane.",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
  end

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "source record validates controlled reference metadata" do
    record = @project.source_records.create!(
      document_id: "ration-log-001",
      evidence_type: "evidence.ration_log",
      evidence_class: "source_record",
      controlled_uri: "evidence://ration-log-001",
      commitment: "source:ration-log-001",
      disclosure_status: "restricted"
    )

    assert record.valid?
    assert_equal "referenced", record.status
  end

  test "source record projects through integration inbox" do
    record = @project.source_records.create!(
      document_id: "invoice-001",
      evidence_type: "evidence.intervention_delivery",
      controlled_uri: "evidence://invoice-001",
      commitment: "source:invoice-001",
      disclosure_status: "restricted"
    )

    assert_difference "IntegrationEvent.count", 1 do
      perform_enqueued_jobs do
        Agevidence::SourceRecordProjection.new(source_record: record).call
      end
    end

    assert_equal "projected", record.reload.status
    assert_equal "source.manifest_available", record.source_event.event_type
    assert EvidenceProjection.where(projection_type: "source_manifest").exists?
    assert ReceiptOutbox.where(receipt_type: "source_manifest_receipt").exists?
  end

  test "pricing quote preserves versioned scope and breakdown" do
    quote = Agevidence::PricingEngine.new(
      project: @project,
      product_code: "verification_readiness_cycle",
      scope: {
        protocol_complexity: "high",
        evidence_classes: 7,
        source_systems: 4,
        countries: 1,
        relying_parties: 2,
        selective_disclosure: true,
        turnaround_days: 15
      }
    ).quote

    assert_equal "quoted", quote.status
    assert_equal Agevidence::PricingQuote::PRICING_VERSION, quote.pricing_version
    assert quote.amount_cents > Agevidence::ProductCatalog.fetch("verification_readiness_cycle").fetch("base_planning_price_cents")
    assert quote.breakdown_json.any? { |item| item["component"] == "selective_disclosure" || item[:component] == "selective_disclosure" }
  end

  test "artifact order cannot assemble before sandbox checkout" do
    quote = Agevidence::PricingEngine.new(project: @project, product_code: "enterprise_reliance_artifact").quote
    order = @project.artifact_orders.create!(
      pricing_quote: quote,
      product_code: quote.product_code,
      amount_cents: quote.amount_cents,
      currency: quote.currency,
      status: "quoted"
    )

    assert_raises RuntimeError do
      Agevidence::ArtifactOrderFulfillment.new(order: order).call
    end

    assert_equal "quoted", order.reload.status
    order.checkout!
    assert_equal "paid", order.status
  end

  test "paid artifact order assembles a bundle projection" do
    quote = Agevidence::PricingEngine.new(project: @project, product_code: "enterprise_reliance_artifact").quote
    order = @project.artifact_orders.create!(
      pricing_quote: quote,
      product_code: quote.product_code,
      amount_cents: quote.amount_cents,
      currency: quote.currency,
      status: "quoted"
    )
    order.checkout!

    assert_difference "EvidenceBundle.count", 1 do
      Agevidence::ArtifactOrderFulfillment.new(order: order.reload).call
    end

    assert_equal "fulfilled", order.reload.status
    assert_equal "valid", order.evidence_bundle.verification_status
    assert_match(/ink verify-bundle/, order.metadata_json.fetch("verification_command"))
  end
end
