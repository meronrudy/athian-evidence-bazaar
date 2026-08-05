module Api
  module V1
    class ArtifactOrdersController < BaseController
      before_action -> { require_scope!("artifacts:read") }, only: :show
      before_action -> { require_scope!("artifacts:write") }, only: %i[create checkout]
      before_action :set_order, only: %i[show checkout]

      def create
        Agevidence::PriceBookLoader.call unless Agevidence::PriceBook.exists?
        key = idempotency_key!
        existing = Agevidence::ArtifactOrder.find_by(developer_account: current_developer_account, idempotency_key: key)
        return render json: { data: serialize(existing) }, status: :ok if existing

        product_code = order_params.fetch(:product_code)
        price_book = Agevidence::PriceBook.current!(product_code)
        pricing_input = order_params.fetch(:pricing, {}).to_h
        result = Agevidence::ArtifactPricing.new(price_book: price_book, input: pricing_input).call
        project = if order_params[:developer_project_id].present?
                    current_developer_account.developer_projects.find(order_params[:developer_project_id])
                  end

        order = Agevidence::ArtifactOrder.create!(
          developer_account: current_developer_account,
          developer_project: project,
          price_book: price_book,
          idempotency_key: key,
          product_code: product_code,
          currency: result.currency,
          scope: order_params.fetch(:scope, {}).to_h,
          pricing_input: pricing_input,
          pricing_breakdown: result.breakdown,
          quoted_amount_cents: result.amount_cents
        )

        render json: { data: serialize(order) }, status: :created
      end

      def show
        render json: { data: serialize(@order) }
      end

      def checkout
        session = Agevidence::StripeCheckout.new(
          order: @order,
          success_url: checkout_params[:success_url].presence || ENV.fetch("CHECKOUT_SUCCESS_URL"),
          cancel_url: checkout_params[:cancel_url].presence || ENV.fetch("CHECKOUT_CANCEL_URL")
        ).call
        render json: { data: serialize(@order).merge(checkout_url: session.url) }, status: :created
      rescue Agevidence::StripeCheckout::ConfigurationError, KeyError => e
        render_error("billing_not_configured", e.message, :service_unavailable)
      rescue Stripe::StripeError => e
        @order.update!(status: "payment_failed") if @order.persisted?
        render_error("payment_provider_error", e.message, :bad_gateway)
      end

      private

      def set_order
        @order = current_developer_account.artifact_orders.find_by!(external_id: params[:id])
      end

      def order_params
        params.require(:artifact_order).permit(
          :product_code,
          :developer_project_id,
          scope: {},
          pricing: %i[
            evidence_classes source_systems review_hours relying_parties
            selective_disclosure_profiles country_adapters migration_events
            portfolio_companies affected_assets rush
          ]
        )
      end

      def checkout_params
        params.fetch(:checkout, {}).permit(:success_url, :cancel_url)
      end

      def serialize(order)
        {
          id: order.external_id,
          product_code: order.product_code,
          status: order.status,
          currency: order.currency,
          quoted_amount_cents: order.quoted_amount_cents,
          final_amount_cents: order.final_amount_cents,
          billing_model: order.price_book.billing_model,
          developer_project_id: order.developer_project_id,
          pricing_breakdown: order.pricing_breakdown,
          evidence_bundle_id: order.evidence_bundle_id,
          paid_at: order.paid_at,
          fulfilled_at: order.fulfilled_at,
          expires_at: order.expires_at,
          created_at: order.created_at
        }
      end
    end
  end
end
