require "test_helper"

class Campaign::ActivationAndQualificationTest < ActiveSupport::TestCase
  setup do
    @developer_account = Agevidence::DeveloperAccount.create!(name: "Campaign Service Developer", status: "active")
    @project = @developer_account.developer_projects.create!(
      name: "Campaign Service Project",
      project_type: "intervention",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
    @account = Campaign::Account.create!(
      name: "Campaign Service Account",
      country_code: "AU",
      authoritative_system: "source_erp",
      evidence_obligation_code: "scope3_buyer_review",
      developer_account: @developer_account
    )
  end

  test "activation recorder is best effort and records matched account paths" do
    result = Campaign::ActivationRecorder.new(
      campaign_account_id: @account.external_id,
      activation_id: "act_service",
      repository_sha: "f4ec679"
    ).record_project_created(@project)

    assert result.recorded
    assert_equal "started", result.activation_path.status
    assert_equal "developer_quickstart", result.activation_path.path_type
    assert_equal 1, @account.touches.count
  end

  test "activation recorder ignores unknown campaign account without blocking" do
    result = Campaign::ActivationRecorder.new(campaign_account_id: "missing").record_project_created(@project)

    assert_not result.recorded
    assert_equal "ignored", result.status
  end

  test "activation recorder rejects activation ids already owned by another account" do
    other_account = Campaign::Account.create!(name: "Other Campaign Account", country_code: "AU")
    @account.activation_paths.create!(
      external_id: "act_conflict",
      path_type: "developer_quickstart",
      status: "invited"
    )

    result = Campaign::ActivationRecorder.new(
      campaign_account_id: other_account.external_id,
      activation_id: "act_conflict"
    ).record_project_4030_replay_completed

    assert_not result.recorded
    assert_equal "failed", result.status
    assert_match(/belongs to another campaign account/, result.message)
    assert_empty other_account.activation_paths
  end

  test "qualification evaluator creates immutable evidence snapshot" do
    @project.source_records.create!(
      document_id: "real-source-1",
      evidence_type: "evidence.feed_record",
      controlled_uri: "evidence://real-source-1",
      commitment: "source:real-source-1",
      source_system: "source_erp",
      metadata_json: { synthetic_demo: false }
    )
    adapter = Agevidence::ModelAdapter.create!(
      adapter_id: "campaign-test-adapter",
      base_model_id: "fixture",
      provider: "fixture",
      runtime: "fixture",
      status: "reference"
    )
    run = @project.model_runs.create!(
      model_adapter: adapter,
      task: "protocol_evidence_extraction",
      status: "completed"
    )
    run.evidence_gaps.create!(
      gap_type: "missing_independent_support",
      requirement: "Independent support",
      description: "A material evidence gap.",
      severity: "material"
    )

    qualification = Campaign::TechnicalQualificationEvaluator.new(
      campaign_account: @account,
      developer_project: @project
    ).call

    assert_equal "evidence_qualified", qualification.qualification_level
    assert_equal "qualified", qualification.status
    assert_equal 1, qualification.evidence_gap_count
    assert_equal "evidence_qualified", @account.reload.qualification_level
    assert_difference "Campaign::TechnicalQualification.count", 1 do
      Campaign::TechnicalQualificationEvaluator.new(
        campaign_account: @account,
        developer_project: @project
      ).call
    end
  end

  test "qualification sync does not downgrade account state" do
    @account.update!(status: "handed_to_salesforce", qualification_level: "commercially_qualified")

    Campaign::TechnicalQualificationEvaluator.new(
      campaign_account: @account,
      developer_project: @project
    ).call

    assert_equal "handed_to_salesforce", @account.reload.status
    assert_equal "commercially_qualified", @account.qualification_level
  end

  test "commercial handoff queues one idempotent salesforce outbox" do
    qualification = @account.technical_qualifications.create!(
      developer_project: @project,
      status: "qualified",
      qualification_level: "commercially_qualified",
      authoritative_system_confirmed: true,
      supported_event_count: 1,
      evidence_gap_count: 1,
      country_code: "AU",
      named_obligation_code: "scope3_buyer_review",
      named_relying_party_type: "buyer",
      qualification_reason: "Commercially qualified test snapshot.",
      qualified_at: Time.current,
      snapshot_json: { basis: "test" }
    )

    assert_difference "Campaign::ConnectorOutbox.count", 1 do
      Campaign::CommercialHandoffCreator.new(
        campaign_account: @account,
        qualification: qualification,
        product_code: "evidence_architecture_sprint",
        planning_value_cents: 2_500_000,
        scope: { repository_sha: "f4ec679c2dd6a2c40e3dced61c81e8f59f90a397" }
      ).call
    end

    assert_no_difference "Campaign::ConnectorOutbox.count" do
      Campaign::CommercialHandoffCreator.new(
        campaign_account: @account,
        qualification: qualification,
        product_code: "evidence_architecture_sprint",
        planning_value_cents: 2_500_000,
        scope: { repository_sha: "f4ec679c2dd6a2c40e3dced61c81e8f59f90a397" }
      ).call
    end
  end

  test "apollo import does not match accounts on missing external identifiers" do
    Campaign::Account.create!(name: "No Domain Target", country_code: "AU")

    connector = Class.new do
      def search_accounts(_criteria)
        [{ name: "Fresh Apollo Target", country_code: "AU" }]
      end
    end.new

    assert_difference "Campaign::Account.count", 1 do
      Campaign::ApolloDiscoveryImporter.new(connector: connector).import_accounts(country_code: "AU")
    end
  end

  test "salesforce value event requires a known handoff" do
    assert_raises RuntimeError do
      Campaign::SalesforceEventIngestor.new(
        payload: {
          event_type: "engagement.contracted",
          contracted_value_cents: 1_000
        }
      ).call
    end
  end

  test "salesforce account update without a known account is ignored within bounded event handling" do
    result = Campaign::SalesforceEventIngestor.new(
      payload: {
        event_type: "account.updated",
        salesforce_account_id: "sf_missing"
      }
    ).call

    assert_equal true, result[:accepted]
    assert_nil result[:campaign_account_id]
  end

  test "phase10 gate opens only after paid architecture sprint proof" do
    assert_not Campaign::Phase10Gate.new.enabled?

    handoff = phase10_handoff(label: "gate proof", contracted_value_cents: 0, cash_collected_cents: 1_000)
    assert_not Campaign::Phase10Gate.new.enabled?

    handoff.update!(contracted_value_cents: 1_000)
    gate = Campaign::Phase10Gate.new
    assert gate.enabled?
    assert_equal handoff.external_id, gate.proof_handoff.external_id
  end

  test "phase10 proposal references are ignored while gate is closed" do
    handoff = phase10_handoff(label: "gated proposal", salesforce_opportunity_id: "sf_opp_gated_proposal")
    digest = "sha256:#{Digest::SHA256.hexdigest("proposal terms")}"

    result = Campaign::SalesforceEventIngestor.new(
      payload: {
        event_id: "sf_evt_gated_proposal",
        event_type: "proposal.issued",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        salesforce_proposal_id: "sf_prop_gated",
        proposal_reference: "proposal-gated",
        proposal_terms_digest: digest
      }
    ).call

    assert_equal "accepted", handoff.reload.status
    assert_nil handoff.salesforce_proposal_id
    assert_equal false, result.fetch(:phase10).fetch(:enabled)
  end

  test "phase10 salesforce references are recorded after paid proof" do
    handoff = phase10_handoff(
      label: "enabled references",
      contracted_value_cents: 500,
      cash_collected_cents: 400,
      salesforce_opportunity_id: "sf_opp_enabled_refs",
      scope_json: {
        capabilities: [
          { capability_type: "python_sdk_method", capability_identifier: "source_records.create", repository_sha: "f4ec679", support_minutes: 6 }
        ]
      }
    )
    qualification = handoff.campaign_technical_qualification
    qualification_before = qualification.reload.attributes
    proposal_digest = "sha256:#{Digest::SHA256.hexdigest("enabled proposal terms")}"
    contract_digest = "sha256:#{Digest::SHA256.hexdigest("enabled contract terms")}"

    Campaign::SalesforceEventIngestor.new(
      payload: {
        event_id: "sf_evt_enabled_proposal",
        event_type: "proposal.issued",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        salesforce_proposal_id: "sf_prop_enabled",
        proposal_reference: "proposal-enabled",
        proposal_terms_digest: proposal_digest
      }
    ).call
    Campaign::SalesforceEventIngestor.new(
      payload: {
        event_id: "sf_evt_enabled_contract",
        event_type: "engagement.contracted",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        contracted_value_cents: 700,
        contract_reference: "contract-enabled",
        contract_terms_digest: contract_digest,
        occurred_at: "2026-08-05T10:00:00Z"
      }
    ).call
    Campaign::SalesforceEventIngestor.new(
      payload: {
        event_id: "sf_evt_enabled_invoice",
        event_type: "invoice.issued",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        invoice_reference: "invoice-enabled",
        occurred_at: "2026-08-05T11:00:00Z"
      }
    ).call
    Campaign::SalesforceEventIngestor.new(
      payload: {
        event_id: "sf_evt_enabled_cash",
        event_type: "cash.collected",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        cash_collected_cents: 600,
        cash_collection_reference: "cash-enabled",
        occurred_at: "2026-08-05T12:00:00Z"
      }
    ).call

    handoff.reload
    assert_equal "sf_prop_enabled", handoff.salesforce_proposal_id
    assert_equal "proposal-enabled", handoff.proposal_reference
    assert_equal proposal_digest, handoff.proposal_terms_digest
    assert_equal "contract-enabled", handoff.contract_reference
    assert_equal contract_digest, handoff.contract_terms_digest
    assert_equal "invoice-enabled", handoff.invoice_reference
    assert_equal "cash-enabled", handoff.cash_collection_reference
    assert_equal "salesforce", handoff.revenue_system
    assert_equal 700, handoff.contracted_value_cents
    assert_equal 600, handoff.cash_collected_cents
    assert_equal qualification_before, qualification.reload.attributes
    assert_equal 1, @account.capability_attributions.count
  end

  test "duplicate salesforce revenue event does not replace phase10 references" do
    handoff = phase10_handoff(
      label: "duplicate revenue",
      contracted_value_cents: 500,
      cash_collected_cents: 400,
      salesforce_opportunity_id: "sf_opp_duplicate_revenue"
    )

    Campaign::SalesforceEventIngestor.new(
      payload: {
        event_id: "sf_evt_duplicate_cash",
        event_type: "cash.collected",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        cash_collected_cents: 1_000,
        cash_collection_reference: "cash-first"
      }
    ).call
    result = Campaign::SalesforceEventIngestor.new(
      payload: {
        event_id: "sf_evt_duplicate_cash",
        event_type: "cash.collected",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        cash_collected_cents: 2_000,
        cash_collection_reference: "cash-second"
      }
    ).call

    assert result.fetch(:duplicate)
    assert_equal 1_000, handoff.reload.cash_collected_cents
    assert_equal "cash-first", handoff.cash_collection_reference
  end

  test "sandbox artifact checkout does not open phase10 gate" do
    quote = Agevidence::PricingQuote.create!(
      developer_project: @project,
      product_code: "evidence_architecture_sprint",
      status: "quoted",
      pricing_version: Agevidence::PricingQuote::PRICING_VERSION,
      currency: "USD",
      amount_cents: 1_000,
      expires_at: 1.day.from_now
    )
    order = Agevidence::ArtifactOrder.create!(
      developer_project: @project,
      pricing_quote: quote,
      product_code: quote.product_code,
      status: "quoted",
      amount_cents: quote.amount_cents,
      currency: quote.currency
    )

    order.checkout!

    assert_equal "paid", order.reload.status
    assert_not Campaign::Phase10Gate.new.enabled?
  end

  test "salesforce contract event does not downgrade an active customer account" do
    qualification = @account.technical_qualifications.create!(
      developer_project: @project,
      status: "qualified",
      qualification_level: "commercially_qualified",
      authoritative_system_confirmed: true,
      supported_event_count: 1,
      evidence_gap_count: 1,
      country_code: "AU",
      named_obligation_code: "scope3_buyer_review",
      named_relying_party_type: "buyer",
      qualification_reason: "Commercially qualified test snapshot.",
      qualified_at: Time.current,
      snapshot_json: { basis: "test" }
    )
    handoff = @account.commercial_handoffs.create!(
      campaign_technical_qualification: qualification,
      product_code: "evidence_architecture_sprint",
      scope_digest: "sha256:#{Digest::SHA256.hexdigest("salesforce status hardening")}",
      salesforce_opportunity_id: "sf_opp_active"
    )
    @account.update!(status: "active_customer")

    Campaign::SalesforceEventIngestor.new(
      payload: {
        event_type: "engagement.contracted",
        salesforce_opportunity_id: handoff.salesforce_opportunity_id,
        contracted_value_cents: 1_000
      }
    ).call

    assert_equal "active_customer", @account.reload.status
  end

  test "capability attribution skips malformed scope entries and does not inflate value" do
    qualification = @account.technical_qualifications.create!(
      developer_project: @project,
      status: "qualified",
      qualification_level: "commercially_qualified",
      authoritative_system_confirmed: true,
      supported_event_count: 1,
      evidence_gap_count: 1,
      country_code: "AU",
      named_obligation_code: "scope3_buyer_review",
      named_relying_party_type: "buyer",
      qualification_reason: "Commercially qualified test snapshot.",
      qualified_at: Time.current,
      snapshot_json: { basis: "test" }
    )
    handoff = @account.commercial_handoffs.create!(
      campaign_technical_qualification: qualification,
      product_code: "evidence_architecture_sprint",
      status: "contracted",
      scope_digest: "sha256:#{Digest::SHA256.hexdigest("campaign capability hardening")}",
      contracted_value_cents: 1_000,
      scope_json: {
        capabilities: [
          "not-a-capability",
          { capability_type: "email_open", capability_identifier: "excluded", repository_sha: "f4ec679" },
          { capability_type: "python_sdk_method", capability_identifier: "source_records.create", repository_sha: "f4ec679", support_minutes: 12 }
        ]
      }
    )

    assert_difference "Campaign::CapabilityAttribution.count", 1 do
      Campaign::CapabilityAttributionRecorder.new(handoff: handoff).record_contract!
      Campaign::CapabilityAttributionRecorder.new(handoff: handoff).record_contract!
    end

    attribution = Campaign::CapabilityAttribution.last
    assert_equal "python_sdk_method", attribution.capability_type
    assert_equal 1_000, attribution.contracted_value_cents
    assert_equal 1, attribution.reuse_count
    assert_equal 12, attribution.support_minutes
  end

  private

  def phase10_qualification(account = @account)
    account.technical_qualifications.create!(
      developer_project: @project,
      status: "qualified",
      qualification_level: "commercially_qualified",
      authoritative_system_confirmed: true,
      supported_event_count: 1,
      evidence_gap_count: 1,
      country_code: account.country_code,
      named_obligation_code: "scope3_buyer_review",
      named_relying_party_type: "buyer",
      qualification_reason: "Commercially qualified test snapshot.",
      qualified_at: Time.current,
      snapshot_json: { basis: "test" }
    )
  end

  def phase10_handoff(label:, account: @account, contracted_value_cents: 0, cash_collected_cents: 0, salesforce_opportunity_id: nil, scope_json: {})
    account.commercial_handoffs.create!(
      campaign_technical_qualification: phase10_qualification(account),
      product_code: "evidence_architecture_sprint",
      scope_digest: "sha256:#{Digest::SHA256.hexdigest(label)}",
      contracted_value_cents: contracted_value_cents,
      cash_collected_cents: cash_collected_cents,
      salesforce_opportunity_id: salesforce_opportunity_id,
      scope_json: scope_json
    )
  end
end
