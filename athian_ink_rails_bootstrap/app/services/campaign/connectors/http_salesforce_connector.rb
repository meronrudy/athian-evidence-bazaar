require "net/http"

module Campaign
  module Connectors
    class HttpSalesforceConnector < Salesforce
      def initialize(base_url: ENV["SALESFORCE_BASE_URL"], token: ENV["SALESFORCE_ACCESS_TOKEN"])
        @base_url = base_url
        @token = token
      end

      def upsert_account(account)
        post_json("/campaign/accounts", account: { external_id: account.external_id, name: account.name, domain: account.domain })
      end

      def upsert_contact(contact)
        post_json("/campaign/contacts", contact: { external_id: contact.external_id, display_name: contact.display_name, email_domain: contact.email_domain })
      end

      def create_opportunity(handoff)
        post_json("/campaign/opportunities", handoff: handoff_payload(handoff))
      end

      def update_opportunity(handoff)
        post_json("/campaign/opportunities/#{handoff.salesforce_opportunity_id}", handoff: handoff_payload(handoff))
      end

      def fetch_opportunity(opportunity_id)
        get_json("/campaign/opportunities/#{opportunity_id}")
      end

      private

      attr_reader :base_url, :token

      def handoff_payload(handoff)
        {
          external_id: handoff.external_id,
          campaign_account_id: handoff.campaign_account.external_id,
          product_code: handoff.product_code,
          planning_value_cents: handoff.planning_value_cents,
          scope_digest: handoff.scope_digest
        }.tap do |payload|
          opportunity_summary = Campaign::OpportunitySummaryBuilder.new(handoff: handoff).call
          payload[:opportunity_summary] = opportunity_summary if opportunity_summary.present?
        end
      end

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
        raise "SALESFORCE_BASE_URL is not configured" if base_url.blank?

        URI.join(base_url, path)
      end

      def perform(uri, request)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{token}" if token.present?
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
        raise "Salesforce connector failed with #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body.presence || "{}")
      end
    end
  end
end
