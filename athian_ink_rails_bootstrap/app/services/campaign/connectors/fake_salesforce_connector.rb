module Campaign
  module Connectors
    class FakeSalesforceConnector < Salesforce
      def upsert_account(account)
        {
          salesforce_account_id: account.salesforce_account_id.presence || "sf_acct_#{account.external_id}",
          status: "upserted",
          fake: true
        }
      end

      def upsert_contact(contact)
        {
          salesforce_contact_id: contact.salesforce_contact_id.presence || "sf_contact_#{contact.external_id}",
          status: "upserted",
          fake: true
        }
      end

      def create_opportunity(handoff)
        {
          salesforce_opportunity_id: handoff.salesforce_opportunity_id.presence || "sf_opp_#{handoff.external_id}",
          opportunity_summary: Campaign::OpportunitySummaryBuilder.new(handoff: handoff).call,
          status: "created",
          fake: true
        }
      end

      def update_opportunity(handoff)
        {
          salesforce_opportunity_id: handoff.salesforce_opportunity_id,
          status: "updated",
          fake: true
        }
      end

      def fetch_opportunity(opportunity_id)
        {
          salesforce_opportunity_id: opportunity_id,
          stage: "Architecture Sprint Scoped",
          fake: true
        }
      end
    end
  end
end
