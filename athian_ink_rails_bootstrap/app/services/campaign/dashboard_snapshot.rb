module Campaign
  class DashboardSnapshot
    def call
      phase10_gate = Campaign::Phase10Gate.new
      {
        counts: {
          accounts: Campaign::Account.count,
          approved_for_outreach: Campaign::Account.where(status: "approved_for_outreach").count,
          developer_activated: Campaign::Account.where(qualification_level: "developer_activated").count,
          evidence_qualified: Campaign::Account.where(qualification_level: "evidence_qualified").count,
          reliance_qualified: Campaign::Account.where(qualification_level: "reliance_qualified").count,
          commercially_qualified: Campaign::Account.where(qualification_level: "commercially_qualified").count,
          handoffs: Campaign::CommercialHandoff.count,
          outbox_backlog: Campaign::ConnectorOutbox.where(status: %w[pending retrying]).count
        },
        phase10: phase10_gate.status_payload.merge(
          proposal_reference_count: Campaign::CommercialHandoff.where.not(salesforce_proposal_id: nil).count,
          contract_reference_count: Campaign::CommercialHandoff.where.not(contract_reference: nil).count,
          cash_reference_count: Campaign::CommercialHandoff.where.not(cash_collection_reference: nil).count
        ),
        recent_accounts: Campaign::Account.order(updated_at: :desc).limit(10),
        recent_activations: Campaign::ActivationPath.includes(:campaign_account).order(updated_at: :desc).limit(10),
        recent_qualifications: Campaign::TechnicalQualification.includes(:campaign_account).order(created_at: :desc).limit(10),
        recent_handoffs: Campaign::CommercialHandoff.includes(:campaign_account).order(updated_at: :desc).limit(10)
      }
    end
  end
end
