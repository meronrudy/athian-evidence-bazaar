module Api
  module V1
    class ProductsController < BaseController
      before_action -> { require_scope!("products:read") }
      before_action :ensure_price_book

      def index
        products = Agevidence::PriceBook.active.order(:billing_model, :base_amount_cents)
        render json: { data: products.map { |product| serialize(product) } }
      end

      def show
        product = Agevidence::PriceBook.current!(params[:id])
        render json: { data: serialize(product) }
      end

      private

      def ensure_price_book
        Agevidence::PriceBookLoader.call unless Agevidence::PriceBook.exists?
      end

      def serialize(product)
        {
          product_code: product.product_code,
          version: product.version,
          name: product.name,
          currency: product.currency,
          billing_model: product.billing_model,
          base_amount_cents: product.base_amount_cents,
          minimum_amount_cents: product.minimum_amount_cents,
          unit_name: product.unit_name,
          included_units: product.included_units,
          overage_amount_cents: product.overage_amount_cents,
          quote_dimensions: product.dimensions.keys
        }
      end
    end
  end
end
