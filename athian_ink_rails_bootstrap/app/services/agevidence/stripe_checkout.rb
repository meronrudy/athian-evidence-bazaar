module Agevidence
  class StripeCheckout
    class ConfigurationError < StandardError; end

    def initialize(order:, success_url:, cancel_url:)
      @order = order
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      configure!
      raise ArgumentError, "order is not payable" unless order.payable?

      billing_account = BillingAccount.find_or_create_by!(developer_account: order.developer_account) do |account|
        account.billing_email = order.developer_account.try(:billing_email)
        account.status = "pending"
      end
      customer_id = billing_account.customer_id.presence || create_customer!(billing_account)
      mode = order.price_book.recurring? ? "subscription" : "payment"

      session_attributes = {
        mode: mode,
        customer: customer_id,
        client_reference_id: order.external_id,
        success_url: success_url,
        cancel_url: cancel_url,
        automatic_tax: { enabled: ENV.fetch("STRIPE_AUTOMATIC_TAX", "false") == "true" },
        line_items: [line_item],
        metadata: metadata
      }
      session_attributes[:payment_intent_data] = { metadata: metadata } if mode == "payment"
      session_attributes[:subscription_data] = { metadata: metadata } if mode == "subscription"

      session = Stripe::Checkout::Session.create(session_attributes, { idempotency_key: order.idempotency_key })
      order.update!(
        status: "checkout_pending",
        checkout_provider: "stripe",
        checkout_session_id: session.id
      )
      session
    end

    private

    attr_reader :order, :success_url, :cancel_url

    def configure!
      key = ENV["STRIPE_SECRET_KEY"].presence
      raise ConfigurationError, "STRIPE_SECRET_KEY is not configured" unless key

      Stripe.api_key = key
    end

    def create_customer!(billing_account)
      customer = Stripe::Customer.create(
        {
          email: billing_account.billing_email,
          name: order.developer_account.name,
          metadata: { developer_account_id: order.developer_account_id.to_s }
        },
        { idempotency_key: "billing-account-#{billing_account.id}" }
      )
      billing_account.update!(customer_id: customer.id, status: "active")
      customer.id
    end

    def line_item
      price_data = {
        currency: order.currency,
        unit_amount: order.quoted_amount_cents,
        product_data: {
          name: order.price_book.name,
          description: "Athian AgEvidence #{order.product_code}",
          metadata: { product_code: order.product_code, price_book_version: order.price_book.version }
        }
      }
      if order.price_book.recurring?
        price_data[:recurring] = { interval: order.price_book.billing_model == "annual" ? "year" : "month" }
      end

      { quantity: 1, price_data: price_data }
    end

    def metadata
      {
        artifact_order_id: order.id.to_s,
        artifact_order_external_id: order.external_id,
        developer_account_id: order.developer_account_id.to_s,
        product_code: order.product_code,
        price_book_version: order.price_book.version
      }
    end
  end
end
