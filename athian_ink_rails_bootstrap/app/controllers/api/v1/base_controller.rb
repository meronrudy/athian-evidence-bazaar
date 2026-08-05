module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_client!
      before_action :enforce_rate_limit!

      rescue_from ActiveRecord::RecordNotFound do |error|
        render_error("not_found", error.message, :not_found)
      end

      rescue_from ActiveRecord::RecordInvalid do |error|
        render_error("validation_error", error.record.errors.full_messages.join(", "), :unprocessable_entity)
      end

      rescue_from ActionController::ParameterMissing do |error|
        render_error("invalid_request", error.message, :bad_request)
      end

      rescue_from ArgumentError do |error|
        render_error("invalid_request", error.message, :unprocessable_entity)
      end

      private

      attr_reader :current_api_client

      def current_developer_account
        current_api_client.developer_account
      end

      def authenticate_api_client!
        raw_token = request.authorization.to_s.match(/\ABearer\s+(.+)\z/i)&.captures&.first
        return render_error("unauthorized", "missing bearer token", :unauthorized) if raw_token.blank?

        client = Agevidence::ApiClient.active.find_by(token_prefix: raw_token.first(18))
        unless client&.usable? && client.authenticate_token(raw_token)
          return render_error("unauthorized", "invalid or expired API token", :unauthorized)
        end

        @current_api_client = client
        client.touch_usage!
      end

      def require_scope!(scope)
        return if current_api_client.allows?(scope)

        render_error("forbidden", "API token lacks #{scope}", :forbidden)
      end

      def enforce_rate_limit!
        return unless current_api_client

        bucket = Time.current.utc.strftime("%Y%m%d%H%M")
        key = "agevidence:rate:#{current_api_client.id}:#{bucket}"
        count = Rails.cache.increment(key, 1, expires_in: 90)
        response.set_header("X-RateLimit-Limit", current_api_client.rate_limit_per_minute.to_s)
        response.set_header("X-RateLimit-Remaining", [current_api_client.rate_limit_per_minute - count.to_i, 0].max.to_s)
        return if count.to_i <= current_api_client.rate_limit_per_minute

        render_error("rate_limited", "rate limit exceeded", :too_many_requests)
      end

      def idempotency_key!
        request.headers["Idempotency-Key"].presence || raise(ActionController::ParameterMissing, "Idempotency-Key")
      end

      def render_error(code, message, status, details: nil)
        render json: { error: { code: code, message: message, details: details } }.compact, status: status
      end
    end
  end
end
