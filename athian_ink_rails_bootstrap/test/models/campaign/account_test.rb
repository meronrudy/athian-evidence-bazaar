require "test_helper"

class Campaign::AccountTest < ActiveSupport::TestCase
  test "account validates bounded campaign identity" do
    developer_account = Agevidence::DeveloperAccount.create!(name: "Campaign Linked Developer", status: "active")
    account = Campaign::Account.create!(
      name: "Campaign Target",
      country_code: "au",
      domain: "TARGET.EXAMPLE",
      developer_account: developer_account,
      priority_score: 88,
      capital_raised_cents: 1_000
    )

    assert account.valid?
    assert_match(/\Acamp_/, account.external_id)
    assert_equal "AU", account.country_code
    assert_equal "target.example", account.domain
    assert_equal [account], developer_account.campaign_accounts.to_a
  end

  test "account rejects invalid status priority value and private metadata" do
    account = Campaign::Account.new(
      name: "Bad Campaign Target",
      country_code: "AUS",
      status: "scientifically_approved",
      qualification_level: "paid",
      priority_score: 101,
      capital_raised_cents: -1,
      metadata_json: { raw_email_body: "private message" }
    )

    assert_not account.valid?
    assert_includes account.errors[:country_code], "must be a two-character country code"
    assert account.errors[:status].present?
    assert account.errors[:qualification_level].present?
    assert account.errors[:priority_score].present?
    assert account.errors[:capital_raised_cents].present?
    assert account.errors[:metadata_json].present?
  end

  test "contact refs reject duplicate connector identifiers" do
    account = Campaign::Account.create!(name: "Contact Campaign Target", country_code: "AU")
    account.contact_refs.create!(display_name: "Technical Sponsor", apollo_person_id: "apollo_person_1", contactability_status: "contactable")
    duplicate = account.contact_refs.new(display_name: "Other Sponsor", apollo_person_id: "apollo_person_1", contactability_status: "contactable")

    assert_not duplicate.valid?
    assert duplicate.errors[:apollo_person_id].present?
  end

  test "commercial handoff validates reference only phase10 digests" do
    developer_account = Agevidence::DeveloperAccount.create!(name: "Phase 10 Digest Developer", status: "active")
    project = developer_account.developer_projects.create!(
      name: "Phase 10 Digest Project",
      project_type: "intervention",
      protocol_status: "mapping",
      integration_status: "source_registered"
    )
    account = Campaign::Account.create!(name: "Phase 10 Digest Target", country_code: "AU", developer_account: developer_account)
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
    handoff = account.commercial_handoffs.new(
      campaign_technical_qualification: qualification,
      product_code: "evidence_architecture_sprint",
      scope_digest: "sha256:#{Digest::SHA256.hexdigest("phase10 digest test")}",
      proposal_terms_digest: "sha256:not-a-digest",
      contract_terms_digest: "sha256:#{Digest::SHA256.hexdigest("contract terms")}"
    )

    assert_not handoff.valid?
    assert handoff.errors[:proposal_terms_digest].present?
  end
end
