module V1
  module Pricing
    class QuotesController < ActionController::API
      def create
        project = find_project!
        quote = Agevidence::PricingEngine.new(
          project: project,
          product_code: quote_params.require(:product_code),
          scope: quote_params[:scope].presence || {}
        ).quote
        render json: quote_payload(quote), status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: { code: "PROJECT_NOT_FOUND", message: "Project was not found." } }, status: :not_found
      rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing, KeyError => e
        render json: { error: { code: "QUOTE_INVALID", message: e.message } }, status: :unprocessable_entity
      end

      def show
        render json: quote_payload(Agevidence::PricingQuote.find_by!(external_id: params[:external_id]))
      end

      private

      def quote_params
        @quote_params ||= params.require(:quote).permit(:project_id, :product_code, scope: {})
      end

      def find_project!
        id = quote_params.require(:project_id)
        Agevidence::DeveloperProject.find_by(id: id) ||
          ExternalObjectMapping.find_by(
            external_object_type: "project",
            external_object_id: id,
            internal_record_type: "Agevidence::DeveloperProject"
          )&.internal_record ||
          raise(ActiveRecord::RecordNotFound)
      end

      def quote_payload(quote)
        {
          quote_id: quote.external_id,
          product_code: quote.product_code,
          currency: quote.currency,
          amount: quote.amount_cents,
          pricing_version: quote.pricing_version,
          breakdown: quote.breakdown_json,
          status: quote.status,
          expires_at: quote.expires_at&.iso8601,
          accepted_at: quote.accepted_at&.iso8601,
          notice: Agevidence::ProductCatalog.notice
        }
      end
    end
  end
end
