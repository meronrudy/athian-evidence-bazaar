module Api
  module V1
    class StripeWebhooksController < ActionController::API
      def create
        secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")
        event = Stripe::Webhook.construct_event(
          request.raw_post,
          request.headers["Stripe-Signature"],
          secret
        )
        Agevidence::StripeWebhookProcessor.new(event: event).call
        head :ok
      rescue KeyError
        render json: { error: { code: "webhook_not_configured", message: "STRIPE_WEBHOOK_SECRET is not configured" } }, status: :service_unavailable
      rescue JSON::ParserError, Stripe::SignatureVerificationError => e
        render json: { error: { code: "invalid_webhook", message: e.message } }, status: :bad_request
      end
    end
  end
end
