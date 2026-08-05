module V1
  module Developer
    class OperationsController < BaseController
      def show
        operation = IntegrationOperation.find_by!(external_id: params[:external_id])
        render json: {
          operation_id: operation.external_id,
          event_id: operation.integration_event.external_event_id,
          status: operation.status,
          operation_type: operation.operation_type,
          started_at: operation.started_at&.iso8601,
          completed_at: operation.completed_at&.iso8601,
          result: operation.result_json,
          error: {
            code: operation.error_code,
            message: operation.error_message
          }.compact
        }
      end
    end
  end
end
