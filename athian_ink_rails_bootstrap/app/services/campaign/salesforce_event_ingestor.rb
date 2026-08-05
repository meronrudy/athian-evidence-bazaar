module Campaign
  class SalesforceEventIngestor
    ALLOWED_EVENTS = %w[
      account.updated
      opportunity.created
      proposal.issued
      engagement.contracted
      invoice.issued
      cash.collected
      opportunity.closed
    ].freeze

    def initialize(payload:)
      @payload = payload.to_h.deep_stringify_keys
    end

    def call
      event_type = payload.fetch("event_type")
      raise "Unsupported Salesforce event" unless ALLOWED_EVENTS.include?(event_type)

      handoff = find_handoff
      account = find_account(handoff)
      return { accepted: true, duplicate: true, event_type: event_type, handoff_id: handoff.external_id } if duplicate_event?(handoff)

      phase10_result = nil
      ActiveRecord::Base.transaction do
        case event_type
        when "account.updated"
          account.update!(
            salesforce_account_id: payload["salesforce_account_id"].presence || account.salesforce_account_id,
            metadata_json: account.metadata_json.merge("salesforce_last_synced_at" => Time.current.iso8601)
          ) if account
        when "opportunity.created"
          require_handoff!(handoff)
          handoff.update!(salesforce_opportunity_id: required_string!("salesforce_opportunity_id"), status: "accepted", accepted_at: Time.current)
        when "proposal.issued"
          require_handoff!(handoff)
          handoff.update!(status: "accepted", accepted_at: handoff.accepted_at || Time.current)
          phase10_result = record_phase10_references(handoff, event_type)
        when "engagement.contracted"
          require_handoff!(handoff)
          handoff.update!(status: "contracted", contracted_at: Time.current, contracted_value_cents: cents_value!("contracted_value_cents"))
          Campaign::CapabilityAttributionRecorder.new(handoff: handoff).record_contract! if handoff
          account&.advance_status!("contracted")
          phase10_result = record_phase10_references(handoff, event_type)
        when "invoice.issued"
          require_handoff!(handoff)
          phase10_result = record_phase10_references(handoff, event_type)
        when "cash.collected"
          require_handoff!(handoff)
          handoff.update!(status: "cash_recorded", cash_recorded_at: Time.current, cash_collected_cents: cents_value!("cash_collected_cents"))
          Campaign::CapabilityAttributionRecorder.new(handoff: handoff).record_cash! if handoff
          account&.advance_status!("active_customer")
          phase10_result = record_phase10_references(handoff, event_type)
        when "opportunity.closed"
          require_handoff!(handoff)
          handoff.update!(status: "closed")
        end
        mark_processed!(handoff)
      end

      response = { accepted: true, duplicate: false, event_type: event_type, handoff_id: handoff&.external_id, campaign_account_id: account&.external_id }
      response[:phase10] = phase10_result.to_h if phase10_result
      response
    end

    private

    attr_reader :payload

    def find_handoff
      find_by_present(Campaign::CommercialHandoff, :external_id, payload["handoff_id"]) ||
        find_by_present(Campaign::CommercialHandoff, :salesforce_opportunity_id, payload["salesforce_opportunity_id"])
    end

    def find_account(handoff)
      handoff&.campaign_account ||
        find_by_present(Campaign::Account, :external_id, payload["campaign_account_id"]) ||
        find_by_present(Campaign::Account, :salesforce_account_id, payload["salesforce_account_id"])
    end

    def find_by_present(scope, column, value)
      normalized = value.to_s.strip.presence
      return nil unless normalized

      scope.find_by(column => normalized)
    end

    def event_key
      @event_key ||= payload["event_id"].presence ||
                     [payload["event_type"], payload["salesforce_opportunity_id"], payload["handoff_id"], payload["occurred_at"]].compact.join(":")
    end

    def duplicate_event?(handoff)
      handoff && event_key.present? && Array(handoff.metadata_json["processed_salesforce_event_keys"]).include?(event_key)
    end

    def mark_processed!(handoff)
      return unless handoff && event_key.present?

      keys = Array(handoff.metadata_json["processed_salesforce_event_keys"])
      handoff.update!(metadata_json: handoff.metadata_json.merge("processed_salesforce_event_keys" => (keys + [event_key]).uniq))
    end

    def require_handoff!(handoff)
      raise "Salesforce event requires a known commercial handoff" unless handoff
    end

    def required_string!(key)
      value = payload[key].to_s.strip
      raise "#{key} is required" if value.blank?

      value
    end

    def cents_value!(key)
      value = Integer(payload.fetch(key))
      raise "#{key} must be nonnegative" if value.negative?

      value
    rescue ArgumentError, TypeError, KeyError
      raise "#{key} must be an integer number of cents"
    end

    def record_phase10_references(handoff, event_type)
      Campaign::SalesforceRevenueReferenceRecorder.new(handoff: handoff, payload: payload).call(event_type)
    end
  end
end
