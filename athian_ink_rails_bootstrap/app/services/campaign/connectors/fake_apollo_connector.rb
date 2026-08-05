module Campaign
  module Connectors
    class FakeApolloConnector < Apollo
      def search_accounts(criteria)
        country_code = criteria[:country_code] || criteria["country_code"] || "AU"
        [
          {
            apollo_account_id: "apollo_acct_southern_pastures",
            name: "Southern Pastures Analytics",
            domain: "southernpastures.example",
            country_code: country_code,
            subsector: "Livestock methane analytics"
          }
        ]
      end

      def enrich_account(account)
        {
          apollo_account_id: account.apollo_account_id.presence || "apollo_acct_#{account.external_id}",
          funding_stage: account.funding_stage.presence || "Series A",
          enriched_at: Time.current.iso8601
        }
      end

      def search_people(account)
        [
          {
            apollo_person_id: "apollo_person_tech_#{account.external_id}",
            display_name: "Technical Sponsor",
            role_category: "technical",
            email_domain: account.domain,
            technical_authority: true
          }
        ]
      end

      def enroll_contact(payload)
        {
          external_reference: payload["external_reference"].presence || "apollo_sequence_#{SecureRandom.alphanumeric(12).downcase}",
          status: "enrolled",
          fake: true
        }
      end

      def fetch_sequence_status(external_reference)
        {
          external_reference: external_reference,
          status: "sent",
          fake: true
        }
      end
    end
  end
end
