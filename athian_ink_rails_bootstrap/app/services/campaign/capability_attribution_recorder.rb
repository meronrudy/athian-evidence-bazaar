module Campaign
  class CapabilityAttributionRecorder
    def initialize(handoff:)
      @handoff = handoff
      @account = handoff.campaign_account
    end

    def record_contract!
      record_values!(
        contracted_value_cents: handoff.contracted_value_cents,
        cash_collected_cents: 0
      )
    end

    def record_cash!
      record_values!(
        contracted_value_cents: 0,
        cash_collected_cents: handoff.cash_collected_cents
      )
    end

    private

    attr_reader :handoff, :account

    def record_values!(contracted_value_cents:, cash_collected_cents:)
      capabilities.each do |capability|
        attribution = account.capability_attributions.find_or_initialize_by(
          campaign_commercial_handoff: handoff,
          capability_type: capability.fetch("capability_type"),
          capability_identifier: capability.fetch("capability_identifier"),
          repository_sha: capability.fetch("repository_sha")
        )
        attribution.assign_attributes(
          source_event_type: capability["source_event_type"],
          country_adapter_identifier: capability["country_adapter_identifier"],
          artifact_product_code: capability["artifact_product_code"] || handoff.product_code,
          contracted_value_cents: [attribution.contracted_value_cents, contracted_value_cents.to_i].max,
          cash_collected_cents: [attribution.cash_collected_cents, cash_collected_cents.to_i].max,
          support_minutes: [attribution.support_minutes, capability["support_minutes"].to_i].max,
          reuse_count: [attribution.reuse_count, 1].max,
          metadata_json: attribution.metadata_json.merge("last_recorded_from_handoff" => handoff.external_id)
        )
        attribution.save!
      end
    end

    def capabilities
      Array(handoff.scope_json["capabilities"]).filter_map do |capability|
        capability.deep_stringify_keys if capability.respond_to?(:deep_stringify_keys)
      end.select do |capability|
        Campaign::CapabilityAttribution::CAPABILITY_TYPES.include?(capability["capability_type"]) &&
          capability["capability_identifier"].present? &&
          capability["repository_sha"].to_s.match?(/\A[a-f0-9]{7,40}\z/)
      end
    end
  end
end
