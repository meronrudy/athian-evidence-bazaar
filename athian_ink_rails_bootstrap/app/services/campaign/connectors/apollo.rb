module Campaign
  module Connectors
    class Apollo
      def self.default
        if Rails.env.development? || Rails.env.test? || ENV["CAMPAIGN_APOLLO_MODE"] == "fake"
          FakeApolloConnector.new
        else
          HttpApolloConnector.new
        end
      end

      def search_accounts(_criteria)
        raise NotImplementedError
      end

      def enrich_account(_account)
        raise NotImplementedError
      end

      def search_people(_account)
        raise NotImplementedError
      end

      def enroll_contact(_payload)
        raise NotImplementedError
      end

      def fetch_sequence_status(_external_reference)
        raise NotImplementedError
      end
    end
  end
end
