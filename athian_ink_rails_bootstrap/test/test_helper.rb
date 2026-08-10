ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: 1)

  def create_demo_protocol(code: "T-1")
    Protocol.create!(
      code: code,
      name: "Test Protocol",
      version: "v1",
      governance_version: "ATH-GOV-TEST",
      status: "active"
    )
  end

  def create_demo_avsa(protocol: create_demo_protocol, external_id: "A-1")
    Avsa.create!(
      protocol: protocol,
      external_id: external_id,
      title: "Test AVSA",
      producer_name: "Producer",
      verified_quantity: 100,
      unit: "tCO2e",
      local_verification_status: "indeterminate",
      methodology_name: "VM0042",
      methodology_version: "v2.2"
    )
  end

  def create_demo_receipt(avsa:, receipt_type: "practice_receipt", title: "Practice Receipt", sequence: 1, lifecycle_state: "sealed", integrity_status: "valid", parents: [])
    issued = InkReceipts.issue(
      payload: { avsa: avsa.external_id, receipt_type: receipt_type, title: title, sequence: sequence },
      issuer: "Athian Test",
      receipt_type: receipt_type,
      schema: "athian.#{receipt_type}.v1",
      parents: parents.map(&:body_digest),
      lifecycle: lifecycle_state,
      avsa: avsa.external_id,
      signer: "did:key:test-#{sequence}"
    )

    avsa.receipts.create!(
      receipt_type: receipt_type,
      title: title,
      lifecycle_state: lifecycle_state,
      domain_state: "test",
      issuer_name: issued.fetch(:issuer),
      signer_key_id: issued.fetch(:signer_key_id),
      schema_id: issued.fetch(:schema_id),
      schema_digest: issued.fetch(:schema_digest),
      body_digest: issued.fetch(:body_digest),
      evidence_commitment: issued.fetch(:evidence_commitment),
      policy_commitment: issued.fetch(:policy_commitment),
      trace_commitment: issued.fetch(:trace_commitment),
      sequence: sequence,
      parent_receipt_ids: parents.map(&:id),
      canonical_encoding_hex: issued.fetch(:canonical_encoding_hex),
      integrity_status: integrity_status
    )
  end

  def agevidence_developer_accounts(_fixture_name)
    @agevidence_developer_account ||= Agevidence::DeveloperAccount.create!(
      name: "Fixture Developer #{SecureRandom.alphanumeric(8)}",
      funding_stage: "Seed",
      capital_raised_cents: 1_000_000,
      primary_segment: "Livestock methane",
      status: "active"
    )
  end

  def agevidence_developer_projects(_fixture_name)
    @agevidence_developer_project ||= agevidence_developer_accounts(:one).developer_projects.create!(
      name: "Fixture Evidence Project #{SecureRandom.alphanumeric(8)}",
      project_type: "intervention",
      target_claim: "The intervention reduces enteric methane.",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
  end

  def agevidence_pricing_quotes(_fixture_name)
    @agevidence_pricing_quote ||= agevidence_developer_projects(:one).pricing_quotes.create!(
      product_code: "verification_readiness_cycle",
      pricing_version: Agevidence::PricingQuote::PRICING_VERSION,
      currency: "USD",
      amount_cents: 2_500_000,
      input_json: { fixture: true },
      breakdown_json: [],
      status: "quoted",
      expires_at: 30.days.from_now
    )
  end
end
