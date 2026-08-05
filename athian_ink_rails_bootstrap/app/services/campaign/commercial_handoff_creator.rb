module Campaign
  class CommercialHandoffCreator
    def initialize(campaign_account:, qualification:, product_code:, planning_value_cents:, scope:, currency: "USD")
      @campaign_account = campaign_account
      @qualification = qualification
      @product_code = product_code
      @planning_value_cents = planning_value_cents.to_i
      @scope = scope.to_h.deep_stringify_keys
      @currency = currency
    end

    def call
      raise "Qualification must be commercially_qualified" unless qualification.qualification_level == "commercially_qualified"
      raise "Qualification must belong to campaign account" unless qualification.campaign_account_id == campaign_account.id

      digest = scope_digest
      handoff = Campaign::CommercialHandoff.find_or_create_by!(
        campaign_account: campaign_account,
        campaign_technical_qualification: qualification,
        product_code: product_code,
        scope_digest: digest
      ) do |record|
        record.status = "ready"
        record.planning_value_cents = planning_value_cents
        record.currency = currency
        record.scope_json = scope
      end

      outbox = enqueue_salesforce_handoff!(handoff)
      Campaign::DeliverConnectorOutboxJob.perform_later(outbox.id) if outbox.status.in?(%w[pending retrying])
      handoff
    end

    private

    attr_reader :campaign_account, :qualification, :product_code, :planning_value_cents, :scope, :currency

    def scope_digest
      canonical = JSON.generate(canonical_value(scope))
      "sha256:#{Digest::SHA256.hexdigest(canonical)}"
    end

    def canonical_value(value)
      case value
      when Hash
        value.keys.sort.each_with_object({}) { |key, result| result[key] = canonical_value(value[key]) }
      when Array
        value.map { |item| canonical_value(item) }
      else
        value
      end
    end

    def enqueue_salesforce_handoff!(handoff)
      Campaign::ConnectorOutbox.find_or_create_by!(idempotency_key: idempotency_key(handoff)) do |outbox|
        outbox.destination = "salesforce"
        outbox.event_type = "architecture_sprint.qualified"
        outbox.aggregate_type = handoff.class.name
        outbox.aggregate_id = handoff.id
        outbox.payload_json = payload_for(handoff)
        outbox.status = "pending"
      end
    end

    def idempotency_key(handoff)
      "salesforce-handoff:#{campaign_account.external_id}:#{qualification.external_id}:#{handoff.product_code}"
    end

    def payload_for(handoff)
      snapshot = qualification.snapshot_json
      {
        event_type: "architecture_sprint.qualified",
        campaign_account_id: campaign_account.external_id,
        developer_project_id: qualification.developer_project_id,
        country_code: qualification.country_code || campaign_account.country_code,
        product_code: handoff.product_code,
        scope_digest: handoff.scope_digest,
        planning_value_cents: handoff.planning_value_cents,
        evidence_gap_count: qualification.evidence_gap_count,
        named_obligation_code: qualification.named_obligation_code,
        repository_sha: scope["repository_sha"] || snapshot["repository_sha"] || "f4ec679c2dd6a2c40e3dced61c81e8f59f90a397"
      }.tap do |payload|
        opportunity_summary = Campaign::OpportunitySummaryBuilder.new(handoff: handoff).call
        payload[:opportunity_summary] = opportunity_summary if opportunity_summary.present?
      end
    end
  end
end
