require "net/http"

module Campaign
  module Connectors
    class HttpApolloConnector < Apollo
      def initialize(base_url: ENV["APOLLO_BASE_URL"], api_key: ENV["APOLLO_API_KEY"])
        @base_url = base_url
        @api_key = api_key
      end

      def search_accounts(criteria)
        post_json("/campaign/search_accounts", criteria)
      end

      def enrich_account(account)
        post_json("/campaign/enrich_account", { apollo_account_id: account.apollo_account_id, domain: account.domain })
      end

      def search_people(account)
        post_json("/campaign/search_people", { apollo_account_id: account.apollo_account_id, domain: account.domain })
      end

      def enroll_contact(payload)
        post_json("/campaign/enroll_contact", payload)
      end

      def fetch_sequence_status(external_reference)
        get_json("/campaign/sequence_status/#{external_reference}")
      end

      private

      attr_reader :base_url, :api_key

      def post_json(path, payload)
        uri = uri_for(path)
        request = Net::HTTP::Post.new(uri)
        request.body = JSON.generate(payload)
        perform(uri, request)
      end

      def get_json(path)
        uri = uri_for(path)
        perform(uri, Net::HTTP::Get.new(uri))
      end

      def uri_for(path)
        raise "APOLLO_BASE_URL is not configured" if base_url.blank?

        URI.join(base_url, path)
      end

      def perform(uri, request)
        request["Content-Type"] = "application/json"
        request["X-Api-Key"] = api_key if api_key.present?
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
        raise "Apollo connector failed with #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body.presence || "[]")
      end
    end
  end
end
