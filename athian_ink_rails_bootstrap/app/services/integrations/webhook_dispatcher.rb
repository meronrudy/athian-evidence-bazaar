module Integrations
  class WebhookDispatcher
    def initialize(integration_source:, event_type:, payload:)
      @integration_source = integration_source
      @event_type = event_type
      @payload = payload.deep_stringify_keys
    end

    def call
      endpoints.map do |endpoint|
        create_delivery(endpoint)
      end
    end

    private

    attr_reader :integration_source, :event_type, :payload

    def endpoints
      integration_source.integration_webhook_endpoints.where(status: "active").select do |endpoint|
        subscribed = Array(endpoint.subscribed_event_types)
        subscribed.empty? || subscribed.include?(event_type)
      end
    end

    def create_delivery(endpoint)
      event_id = "out_evt_#{SecureRandom.alphanumeric(26).downcase}"
      body = payload.merge(
        "event_id" => event_id,
        "event_type" => event_type,
        "occurred_at" => Time.current.iso8601
      )
      canonical = InkReceipts.canonicalize_integration_event(body)
      digest = InkReceipts.integration_payload_digest(canonical)
      delivery = endpoint.integration_deliveries.create!(
        event_type: event_type,
        external_id: event_id,
        payload_json: body,
        payload_digest: digest,
        idempotency_key: "#{endpoint.id}:#{event_type}:#{digest}",
        status: "pending",
        next_attempt_at: Time.current
      )
      Integrations::DeliverWebhookJob.perform_later(delivery.id)
      delivery
    end
  end
end
