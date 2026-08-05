module V1
  module Integrations
    class WebhookEndpointsController < BaseController
      def index
        endpoints = integration_source&.integration_webhook_endpoints || IntegrationWebhookEndpoint.none
        render json: endpoints.order(:id).map { |endpoint| endpoint_payload(endpoint) }
      end

      def create
        unless integration_source&.active_for_ingestion?
          render_error(::Integrations::ErrorCatalog::CODES[:source_unknown], status: :unauthorized)
          return
        end

        endpoint = integration_source.integration_webhook_endpoints.create!(
          url: params.require(:url),
          signing_secret_ciphertext: params.require(:signing_secret),
          subscribed_event_types: params[:subscribed_event_types].presence || ::Integrations::EventRegistry::RESULT_EVENT_TYPES
        )
        render json: endpoint_payload(endpoint), status: :created
      rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
        render json: { error: { code: "WEBHOOK_ENDPOINT_INVALID", message: e.message } }, status: :unprocessable_entity
      end

      def destroy
        endpoint = integration_source.integration_webhook_endpoints.find(params[:id])
        endpoint.update!(status: "disabled")
        head :no_content
      end

      private

      def endpoint_payload(endpoint)
        {
          id: endpoint.id,
          url: endpoint.url,
          status: endpoint.status,
          subscribed_event_types: endpoint.subscribed_event_types,
          last_success_at: endpoint.last_success_at&.iso8601,
          last_failure_at: endpoint.last_failure_at&.iso8601
        }
      end
    end
  end
end
