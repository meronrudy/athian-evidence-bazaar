module Campaign
  class OutreachEnroller
    ACCOUNT_OUTREACH_LIMIT = 3

    def initialize(contact:, content_reference:, technical_hypothesis:, connector: Campaign::Connectors::Apollo.default)
      @contact = contact
      @account = contact.campaign_account
      @content_reference = content_reference
      @technical_hypothesis = technical_hypothesis
      @connector = connector
    end

    def call
      raise "Account must be approved for outreach" unless account.status == "approved_for_outreach"
      raise "Contact is terminally unsubscribed" if contact.unsubscribed? || contact.contactability_status == "suppressed"
      raise "Account outreach cap reached" if account.touches.where(touch_type: "outreach.sent").count >= ACCOUNT_OUTREACH_LIMIT
      raise "Technical hypothesis is required" if technical_hypothesis.blank?
      raise "Content reference is required" if content_reference.blank?

      outbox = Campaign::ConnectorOutbox.create!(
        destination: "apollo",
        event_type: "outreach.sent",
        aggregate_type: contact.class.name,
        aggregate_id: contact.id,
        idempotency_key: "apollo-outreach:#{contact.external_id}:#{Digest::SHA256.hexdigest(content_reference)}",
        payload_json: {
          campaign_account_id: account.external_id,
          campaign_contact_id: contact.external_id,
          external_reference: contact.apollo_person_id,
          content_reference: content_reference,
          technical_hypothesis: technical_hypothesis
        }
      )
      account.touches.create!(
        campaign_contact_ref: contact,
        touch_type: "outreach.sent",
        source_system: "apollo",
        external_reference: outbox.idempotency_key,
        content_reference: content_reference,
        occurred_at: Time.current,
        metadata_json: { "technical_hypothesis" => technical_hypothesis }
      )
      outbox
    end

    private

    attr_reader :contact, :account, :content_reference, :technical_hypothesis, :connector
  end
end
