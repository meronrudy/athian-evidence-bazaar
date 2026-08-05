module Campaign
  class ApolloContactImporter
    def initialize(account:, connector: Campaign::Connectors::Apollo.default)
      @account = account
      @connector = connector
    end

    def call
      connector.search_people(account).map do |payload|
        normalized = payload.deep_stringify_keys
        contact = find_contact(normalized) || account.contact_refs.new
        contact.assign_attributes(
          display_name: normalized["display_name"],
          role_category: normalized["role_category"],
          email_domain: normalized["email_domain"].presence || account.domain,
          apollo_person_id: normalized["apollo_person_id"],
          technical_authority: ActiveModel::Type::Boolean.new.cast(normalized["technical_authority"]),
          commercial_authority: ActiveModel::Type::Boolean.new.cast(normalized["commercial_authority"]),
          scientific_authority: ActiveModel::Type::Boolean.new.cast(normalized["scientific_authority"]),
          contactability_status: normalized["contactability_status"].presence || "unknown",
          last_enriched_at: Time.current
        )
        contact.save!
        account.touches.create!(
          campaign_contact_ref: contact,
          touch_type: "target_contact.discovered",
          source_system: "apollo",
          external_reference: contact.apollo_person_id,
          occurred_at: Time.current,
          metadata_json: { "role_category" => contact.role_category }
        )
        contact
      end
    end

    private

    attr_reader :account, :connector

    def find_contact(payload)
      find_by_present(:salesforce_contact_id, payload["salesforce_contact_id"]) ||
        find_by_present(:apollo_person_id, payload["apollo_person_id"])
    end

    def find_by_present(column, value)
      normalized = value.to_s.strip.presence
      return nil unless normalized

      account.contact_refs.find_by(column => normalized)
    end
  end
end
