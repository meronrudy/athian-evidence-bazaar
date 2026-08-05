module V1
  module Pricing
    class ProductsController < ActionController::API
      def index
        render json: {
          notice: Agevidence::ProductCatalog.notice,
          pricing_factors: Agevidence::ProductCatalog.pricing_factors,
          products: Agevidence::ProductCatalog.all.map { |code, product| product_payload(code, product) }
        }
      end

      def show
        render json: product_payload(params[:code], Agevidence::ProductCatalog.fetch(params[:code]))
      rescue KeyError
        render json: { error: { code: "PRODUCT_NOT_FOUND", message: "Unknown AgEvidence product code." } }, status: :not_found
      end

      private

      def product_payload(code, product)
        {
          code: code,
          name: product.fetch("name"),
          billing_type: product.fetch("billing_type"),
          base_planning_price_cents: product.fetch("base_planning_price_cents"),
          currency: "USD",
          description: product.fetch("description"),
          notice: Agevidence::ProductCatalog.notice
        }
      end
    end
  end
end
