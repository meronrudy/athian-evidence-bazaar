module Api
  module V1
    class QuotesController < BaseController
      before_action -> { require_scope!("artifacts:write") }

      def create
        Agevidence::PriceBookLoader.call unless Agevidence::PriceBook.exists?
        price_book = Agevidence::PriceBook.current!(quote_params.fetch(:product_code))
        result = Agevidence::ArtifactPricing.new(price_book: price_book, input: quote_params.fetch(:pricing, {})).call

        render json: {
          data: {
            product_code: price_book.product_code,
            price_book_version: price_book.version,
            currency: result.currency,
            amount_cents: result.amount_cents,
            billing_model: price_book.billing_model,
            breakdown: result.breakdown,
            expires_in_seconds: 1_209_600
          }
        }
      end

      private

      def quote_params
        params.require(:quote).permit(
          :product_code,
          pricing: %i[
            evidence_classes source_systems review_hours relying_parties
            selective_disclosure_profiles country_adapters migration_events
            portfolio_companies affected_assets rush
          ]
        )
      end
    end
  end
end
