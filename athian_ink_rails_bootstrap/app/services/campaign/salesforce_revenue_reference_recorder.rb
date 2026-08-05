module Campaign
  class SalesforceRevenueReferenceRecorder
    Result = Struct.new(:applied, :enabled, :event_type, :message, keyword_init: true)

    def initialize(handoff:, payload:, gate: Campaign::Phase10Gate.new)
      @handoff = handoff
      @payload = payload.to_h.deep_stringify_keys
      @gate = gate
    end

    def call(event_type)
      return Result.new(applied: false, enabled: false, event_type: event_type, message: "phase10 gated") unless gate.enabled?

      attrs = attributes_for(event_type)
      return Result.new(applied: false, enabled: true, event_type: event_type, message: "no phase10 references supplied") if attrs.blank?

      handoff.update!(attrs)
      Result.new(applied: true, enabled: true, event_type: event_type, message: "phase10 references recorded")
    end

    private

    attr_reader :handoff, :payload, :gate

    def attributes_for(event_type)
      case event_type
      when "proposal.issued"
        compact_attributes(
          salesforce_proposal_id: payload["salesforce_proposal_id"],
          proposal_reference: payload["proposal_reference"],
          proposal_terms_digest: payload["proposal_terms_digest"]
        )
      when "engagement.contracted"
        compact_attributes(
          contract_reference: payload["contract_reference"],
          contract_terms_digest: payload["contract_terms_digest"],
          revenue_system: revenue_system,
          last_revenue_signal_at: occurred_at
        )
      when "invoice.issued"
        compact_attributes(
          invoice_reference: payload["invoice_reference"],
          revenue_system: revenue_system,
          last_revenue_signal_at: occurred_at
        )
      when "cash.collected"
        compact_attributes(
          cash_collection_reference: payload["cash_collection_reference"],
          revenue_system: revenue_system,
          last_revenue_signal_at: occurred_at
        )
      else
        {}
      end
    end

    def compact_attributes(attributes)
      attributes.each_with_object({}) do |(key, value), result|
        next if value.respond_to?(:blank?) ? value.blank? : value.nil?

        result[key] = value
      end
    end

    def revenue_system
      payload["revenue_system"].presence || "salesforce"
    end

    def occurred_at
      raw = payload["occurred_at"].presence
      raw ? Time.zone.parse(raw) : Time.current
    rescue ArgumentError
      Time.current
    end
  end
end
