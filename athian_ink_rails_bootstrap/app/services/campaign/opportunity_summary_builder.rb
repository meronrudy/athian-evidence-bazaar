module Campaign
  class OpportunitySummaryBuilder
    def initialize(handoff:, gate: Campaign::Phase10Gate.new)
      @handoff = handoff
      @gate = gate
    end

    def call
      return nil unless gate.enabled?

      qualification = handoff.campaign_technical_qualification
      account = handoff.campaign_account
      project_ref = qualification.developer_project_id || qualification.snapshot_json["developer_project_id"] || "not linked"

      [
        "Architecture Sprint handoff for #{account.name} (#{account.country_code}).",
        "Product #{handoff.product_code}; planning value #{handoff.planning_value_cents} #{handoff.currency} cents.",
        "Developer project #{project_ref}; qualification #{qualification.external_id} at #{qualification.qualification_level}.",
        "Evidence basis: #{qualification.evidence_gap_count} gap(s), obligation #{qualification.named_obligation_code.presence || "not named"}, relying party #{qualification.named_relying_party_type.presence || "not named"}.",
        "Campaign summary is advisory; Salesforce remains authoritative for opportunity, proposal, contract, forecast, and collection."
      ].join("\n")
    end

    private

    attr_reader :handoff, :gate
  end
end
