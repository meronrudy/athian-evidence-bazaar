require "test_helper"

class Campaign::CampaignApiTest < ActionDispatch::IntegrationTest
  test "campaign account activation and dashboard endpoints work" do
    post "/v1/campaign/accounts",
         params: {
           campaign_account: {
             external_id: "camp_api_test",
             name: "API Campaign Target",
             country_code: "AU",
             priority_score: 50,
             evidence_obligation_code: "scope3_buyer_review"
           }
         },
         as: :json
    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "camp_api_test", payload.fetch("account_id")
    assert_match(/Campaign state does not imply/, payload.fetch("authority_boundary"))

    post "/v1/campaign/accounts/camp_api_test/activations",
         params: {
           activation: {
             external_id: "act_api_test",
             path_type: "python_sdk",
             repository_sha: "f4ec679"
           }
         },
         as: :json
    assert_response :created
    activation_payload = JSON.parse(response.body)
    assert_equal "act_api_test", activation_payload.fetch("activation_id")

    get "/v1/campaign/dashboard", as: :json
    assert_response :success
    dashboard = JSON.parse(response.body)
    assert dashboard.fetch("counts").fetch("accounts") >= 1
  end

  test "salesforce inbound signal updates commercial value only" do
    developer_account = Agevidence::DeveloperAccount.create!(name: "API Handoff Developer", status: "active")
    project = developer_account.developer_projects.create!(
      name: "API Handoff Project",
      project_type: "intervention",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
    account = Campaign::Account.create!(external_id: "camp_sf_api", name: "SF API Account", country_code: "AU", developer_account: developer_account)
    qualification = account.technical_qualifications.create!(
      developer_project: project,
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
    handoff = Campaign::CommercialHandoffCreator.new(
      campaign_account: account,
      qualification: qualification,
      product_code: "evidence_architecture_sprint",
      planning_value_cents: 2_500_000,
      scope: { repository_sha: "f4ec679c2dd6a2c40e3dced61c81e8f59f90a397" }
    ).call

    post "/v1/campaign/connectors/salesforce/events",
         params: {
           event_type: "engagement.contracted",
           handoff_id: handoff.external_id,
           contracted_value_cents: 2_500_000
         },
         as: :json
    assert_response :accepted

    assert_equal 2_500_000, handoff.reload.contracted_value_cents
    assert_equal "commercially_qualified", qualification.reload.qualification_level
  end

  test "salesforce inbound signal exposes gated phase10 references and dashboard status" do
    developer_account = Agevidence::DeveloperAccount.create!(name: "API Phase 10 Developer", status: "active")
    project = developer_account.developer_projects.create!(
      name: "API Phase 10 Project",
      project_type: "intervention",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
    account = Campaign::Account.create!(external_id: "camp_phase10_api", name: "Phase 10 API Account", country_code: "AU", developer_account: developer_account)
    qualification = account.technical_qualifications.create!(
      developer_project: project,
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
    handoff = account.commercial_handoffs.create!(
      campaign_technical_qualification: qualification,
      product_code: "evidence_architecture_sprint",
      scope_digest: "sha256:#{Digest::SHA256.hexdigest("phase10 api")}",
      contracted_value_cents: 1_000,
      cash_collected_cents: 1_000,
      salesforce_opportunity_id: "sf_opp_phase10_api"
    )

    post "/v1/campaign/connectors/salesforce/events",
         params: {
           event_id: "sf_evt_phase10_api_proposal",
           event_type: "proposal.issued",
           salesforce_opportunity_id: handoff.salesforce_opportunity_id,
           salesforce_proposal_id: "sf_prop_phase10_api",
           proposal_reference: "proposal-phase10-api",
           proposal_terms_digest: "sha256:#{Digest::SHA256.hexdigest("phase10 api proposal")}"
         },
         as: :json
    assert_response :accepted

    payload = JSON.parse(response.body)
    assert_equal true, payload.fetch("phase10").fetch("applied")
    assert_equal "sf_prop_phase10_api", handoff.reload.salesforce_proposal_id

    get "/v1/campaign/dashboard", as: :json
    assert_response :success
    dashboard = JSON.parse(response.body)
    assert_equal true, dashboard.fetch("phase10").fetch("enabled")
  end
end
