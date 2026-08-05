module Agevidence
  class StripeWebhookProcessor
    def initialize(event:)
      @event = event
    end

    def call
      webhook_event = WebhookEvent.find_or_initialize_by(provider: "stripe", event_id: event.id)
      return webhook_event if webhook_event.persisted? && webhook_event.status == "processed"

      webhook_event.assign_attributes(event_type: event.type, status: "processing", payload: event.to_hash)
      webhook_event.save!

      case event.type
      when "checkout.session.completed"
        complete_checkout!(event.data.object)
      when "checkout.session.expired"
        expire_checkout!(event.data.object)
      when "invoice.paid"
        mark_invoice_paid!(event.data.object)
      when "invoice.payment_failed"
        mark_invoice_failed!(event.data.object)
      when "customer.subscription.created", "customer.subscription.updated"
        sync_subscription!(event.data.object)
      when "customer.subscription.deleted"
        cancel_subscription!(event.data.object)
      else
        webhook_event.update!(status: "ignored", processed_at: Time.current)
        return webhook_event
      end

      webhook_event.update!(status: "processed", processed_at: Time.current)
      webhook_event
    rescue StandardError => e
      webhook_event&.update!(status: "failed", failure_reason: "#{e.class}: #{e.message}")
      raise
    end

    private

    attr_reader :event

    def complete_checkout!(session)
      order = order_from_metadata(session.metadata)
      payment_intent = session.respond_to?(:payment_intent) ? session.payment_intent : nil
      order.mark_paid!(payment_intent_id: payment_intent)
      sync_subscription_by_id!(session.subscription, order) if session.respond_to?(:subscription) && session.subscription.present?
    end

    def expire_checkout!(session)
      order = order_from_metadata(session.metadata)
      order.update!(status: "expired") unless order.status == "fulfilled"
    end

    def mark_invoice_paid!(invoice)
      subscription = Subscription.find_by(provider_subscription_id: invoice.subscription)
      subscription&.update!(status: "active")
    end

    def mark_invoice_failed!(invoice)
      subscription = Subscription.find_by(provider_subscription_id: invoice.subscription)
      subscription&.update!(status: "past_due")
      subscription&.billing_account&.update!(status: "past_due")
    end

    def sync_subscription_by_id!(provider_subscription_id, order)
      Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")
      provider_subscription = Stripe::Subscription.retrieve(provider_subscription_id)
      sync_subscription!(provider_subscription, order: order)
    end

    def sync_subscription!(provider_subscription, order: nil)
      metadata = provider_subscription.metadata.to_h
      order ||= order_from_metadata(metadata)
      billing_account = BillingAccount.find_or_create_by!(developer_account: order.developer_account)
      billing_account.update!(provider: "stripe", customer_id: provider_subscription.customer, status: billing_status(provider_subscription.status))

      subscription = Subscription.find_or_initialize_by(provider_subscription_id: provider_subscription.id)
      subscription.assign_attributes(
        billing_account: billing_account,
        price_book: order.price_book,
        status: subscription_status(provider_subscription.status),
        quantity: 1,
        current_period_start: unix_time(provider_subscription.current_period_start),
        current_period_end: unix_time(provider_subscription.current_period_end),
        cancel_at_period_end: provider_subscription.cancel_at_period_end,
        metadata: metadata
      )
      subscription.save!
    end

    def cancel_subscription!(provider_subscription)
      subscription = Subscription.find_by(provider_subscription_id: provider_subscription.id)
      subscription&.update!(status: "canceled", cancel_at_period_end: false)
    end

    def order_from_metadata(metadata)
      attributes = metadata.respond_to?(:to_h) ? metadata.to_h : metadata
      order_id = attributes["artifact_order_id"] || attributes[:artifact_order_id]
      ArtifactOrder.find(order_id)
    end

    def unix_time(value)
      value.present? ? Time.zone.at(value) : nil
    end

    def subscription_status(status)
      status.to_s.in?(Subscription::STATUSES) ? status.to_s : "pending"
    end

    def billing_status(status)
      status.to_s == "active" || status.to_s == "trialing" ? "active" : "pending"
    end
  end
end
