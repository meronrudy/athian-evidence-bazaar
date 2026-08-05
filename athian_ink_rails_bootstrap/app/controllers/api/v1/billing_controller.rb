module Api
  module V1
    class BillingController < BaseController
      before_action -> { require_scope!("usage:read") }

      def show
        account = current_developer_account.billing_account
        subscriptions = account&.subscriptions&.includes(:price_book)&.order(created_at: :desc) || []
        orders = current_developer_account.artifact_orders.includes(:price_book).order(created_at: :desc).limit(25)

        render json: {
          data: {
            billing_account: account && {
              provider: account.provider,
              status: account.status,
              currency: account.currency,
              payment_terms_days: account.payment_terms_days,
              monthly_commitment_cents: account.monthly_commitment_cents
            },
            subscriptions: subscriptions.map do |subscription|
              {
                id: subscription.id,
                product_code: subscription.price_book.product_code,
                status: subscription.status,
                current_period_start: subscription.current_period_start,
                current_period_end: subscription.current_period_end,
                cancel_at_period_end: subscription.cancel_at_period_end
              }
            end,
            artifact_orders: orders.map do |order|
              {
                id: order.external_id,
                product_code: order.product_code,
                status: order.status,
                quoted_amount_cents: order.quoted_amount_cents,
                currency: order.currency,
                paid_at: order.paid_at,
                fulfilled_at: order.fulfilled_at
              }
            end
          }
        }
      end
    end
  end
end
