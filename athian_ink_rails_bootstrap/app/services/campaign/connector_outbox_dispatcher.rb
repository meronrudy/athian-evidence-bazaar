module Campaign
  class ConnectorOutboxDispatcher
    MAX_ATTEMPTS = 3

    def initialize(outbox:, salesforce_connector: nil, apollo_connector: nil)
      @outbox = outbox
      @salesforce_connector = salesforce_connector
      @apollo_connector = apollo_connector
    end

    def call
      return outbox if outbox.delivered?

      result = deliver
      ActiveRecord::Base.transaction do
        outbox.lock!
        outbox.update!(attempt_count: outbox.attempt_count + 1)
        outbox.mark_delivered!
        apply_result!(result)
      end
      outbox
    rescue StandardError => e
      outbox.attempt_count + 1 >= MAX_ATTEMPTS ? outbox.dead_letter!(e.message) : outbox.retry_later!(e.message)
      outbox
    end

    private

    attr_reader :outbox

    def deliver
      case outbox.destination
      when "salesforce"
        deliver_salesforce
      when "apollo"
        deliver_apollo
      else
        raise "Unknown connector destination #{outbox.destination}"
      end
    end

    def deliver_salesforce
      handoff = outbox.aggregate
      connector = @salesforce_connector || Campaign::Connectors::Salesforce.default
      account_result = connector.upsert_account(handoff.campaign_account)
      opportunity_result = connector.create_opportunity(handoff)
      { account: account_result, opportunity: opportunity_result }
    end

    def deliver_apollo
      connector = @apollo_connector || Campaign::Connectors::Apollo.default
      connector.enroll_contact(outbox.payload_json)
    end

    def apply_result!(result)
      return unless outbox.destination == "salesforce"

      handoff = outbox.aggregate
      return unless handoff

      account_id = result.dig(:account, :salesforce_account_id) || result.dig("account", "salesforce_account_id")
      opportunity_id = result.dig(:opportunity, :salesforce_opportunity_id) || result.dig("opportunity", "salesforce_opportunity_id")
      handoff.update!(
        status: "sent",
        sent_at: handoff.sent_at || Time.current,
        salesforce_opportunity_id: opportunity_id.presence || handoff.salesforce_opportunity_id,
        metadata_json: handoff.metadata_json.merge("last_sync_result" => result.deep_stringify_keys)
      )
      account = handoff.campaign_account
      account.update!(salesforce_account_id: account_id.presence || account.salesforce_account_id)
      account.advance_status!("handed_to_salesforce")
    end
  end
end
