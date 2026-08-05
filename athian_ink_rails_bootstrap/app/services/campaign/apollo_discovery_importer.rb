module Campaign
  class ApolloDiscoveryImporter
    def initialize(connector: Campaign::Connectors::Apollo.default)
      @connector = connector
    end

    def import_accounts(criteria = {})
      connector.search_accounts(criteria).map do |payload|
        normalized = payload.deep_stringify_keys
        account = find_account(normalized) || Campaign::Account.new
        account.assign_attributes(
          external_id: account.external_id.presence || "camp_#{normalized.fetch("name").parameterize(separator: "_")}",
          name: normalized.fetch("name"),
          domain: normalized["domain"],
          country_code: normalized["country_code"].presence || criteria[:country_code].presence || "AU",
          subsector: normalized["subsector"],
          apollo_account_id: normalized["apollo_account_id"],
          authoritative_system: "apollo",
          status: account.status == "identified" ? "researched" : account.status,
          metadata_json: account.metadata_json.merge("apollo_last_imported_at" => Time.current.iso8601)
        )
        account.save!
        account.touches.create!(
          touch_type: "target_account.discovered",
          source_system: "apollo",
          external_reference: account.apollo_account_id,
          occurred_at: Time.current,
          metadata_json: { "import" => "fake_or_http_apollo" }
        )
        account
      end
    end

    private

    attr_reader :connector

    def find_account(payload)
      find_by_present(:salesforce_account_id, payload["salesforce_account_id"]) ||
        find_by_present(:domain, payload["domain"].to_s.downcase) ||
        find_by_present(:apollo_account_id, payload["apollo_account_id"])
    end

    def find_by_present(column, value)
      normalized = value.to_s.strip.presence
      return nil unless normalized

      Campaign::Account.find_by(column => normalized)
    end
  end
end
