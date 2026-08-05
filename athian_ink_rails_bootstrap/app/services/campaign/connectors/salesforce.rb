module Campaign
  module Connectors
    class Salesforce
      def self.default
        if Rails.env.development? || Rails.env.test? || ENV["CAMPAIGN_SALESFORCE_MODE"] == "fake"
          FakeSalesforceConnector.new
        else
          HttpSalesforceConnector.new
        end
      end

      def upsert_account(_account)
        raise NotImplementedError
      end

      def upsert_contact(_contact)
        raise NotImplementedError
      end

      def create_opportunity(_handoff)
        raise NotImplementedError
      end

      def update_opportunity(_handoff)
        raise NotImplementedError
      end

      def fetch_opportunity(_opportunity_id)
        raise NotImplementedError
      end
    end
  end
end
