module V1
  module Integrations
    class BaseController < ActionController::API
      private

      def integration_source
        @integration_source ||= IntegrationSource.find_by(key: request.headers["X-Athian-Integration-Source"].to_s)
      end

      def render_error(code, status:, event_id: nil, message: nil)
        render json: {
          error: {
            code: code,
            message: message.presence || ::Integrations::ErrorCatalog.message(code),
            event_id: event_id
          }.compact
        }, status: status
      end
    end
  end
end
