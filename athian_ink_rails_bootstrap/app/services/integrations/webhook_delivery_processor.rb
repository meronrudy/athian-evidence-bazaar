require "net/http"

module Integrations
  class WebhookDeliveryProcessor
    RETRY_DELAYS = [1.minute, 5.minutes, 30.minutes, 2.hours, 8.hours, 24.hours].freeze

    def initialize(delivery:)
      @delivery = delivery
      @endpoint = delivery.integration_webhook_endpoint
    end

    def call
      delivery.with_lock do
        return delivery if delivery.status == "delivered"

        delivery.update!(status: "delivering", attempt_count: delivery.attempt_count + 1)
        response = post_delivery
        if response.is_a?(Net::HTTPSuccess)
          delivery.update!(
            status: "delivered",
            response_status: response.code.to_i,
            response_body_excerpt: response.body.to_s.first(500),
            delivered_at: Time.current,
            last_error: nil
          )
          endpoint.update!(last_success_at: Time.current)
        else
          schedule_retry!("Webhook endpoint returned #{response.code}.", response_status: response.code.to_i, body: response.body)
        end
      end
    rescue StandardError => e
      schedule_retry!(e.message)
    end

    private

    attr_reader :delivery, :endpoint

    def post_delivery
      uri = URI.parse(endpoint.url)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-AgEvidence-Event-Id"] = delivery.external_id
      request["X-AgEvidence-Timestamp"] = timestamp
      request["X-AgEvidence-Signature"] = signature
      request.body = body

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
    end

    def body
      @body ||= JSON.generate(delivery.payload_json)
    end

    def timestamp
      @timestamp ||= Time.current.iso8601
    end

    def signature
      canonical = InkReceipts.canonicalize_integration_event(delivery.payload_json)
      InkReceipts.sign_integration_payload(
        secret: endpoint.signing_secret,
        timestamp: timestamp,
        canonical_payload: canonical
      )
    end

    def schedule_retry!(message, response_status: nil, body: nil)
      attempts = delivery.attempt_count
      if attempts >= RETRY_DELAYS.length
        delivery.update!(
          status: "dead_letter",
          response_status: response_status,
          response_body_excerpt: body.to_s.first(500),
          last_error: message
        )
      else
        delivery.update!(
          status: "retrying",
          response_status: response_status,
          response_body_excerpt: body.to_s.first(500),
          last_error: message,
          next_attempt_at: Time.current + RETRY_DELAYS.fetch(attempts)
        )
        Integrations::DeliverWebhookJob.set(wait_until: delivery.next_attempt_at).perform_later(delivery.id)
      end
      endpoint.update!(last_failure_at: Time.current)
    end
  end
end
