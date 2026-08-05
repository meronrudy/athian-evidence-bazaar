module V1
  module Integrations
    class EventsController < BaseController
      def create
        result = ::Integrations::IngestEvent.call(
          integration_source: integration_source,
          raw_body: request.raw_post,
          headers: request.headers
        )

        if result.accepted
          render json: {
            event_id: result.integration_event.external_event_id,
            status: "accepted",
            duplicate: result.duplicate,
            operation_id: result.operation&.external_id
          }, status: :accepted
        else
          render_error(
            result.error_code,
            status: status_for(result.error_code),
            event_id: result.integration_event&.external_event_id,
            message: result.error_message
          )
        end
      end

      def show
        event = scoped_events.find_by!(external_event_id: params[:external_event_id])
        render json: event_payload(event)
      end

      def replay
        event = scoped_events.find_by!(external_event_id: params[:external_event_id])
        unless event.replayable?
          render_error("EVENT_REPLAY_NOT_ALLOWED", status: :unprocessable_entity, event_id: event.external_event_id, message: "The preserved event is not eligible for replay.")
          return
        end

        operation = event.integration_operations.create!(
          operation_type: "event_replay",
          status: "pending",
          idempotency_key: "integration-event-replay:#{event.integration_source.key}:#{event.external_event_id}:#{Time.current.to_i}",
          result_json: { reason: params[:reason].presence || "api_replay" }
        )
        event.update!(processing_status: "accepted", operation_external_id: operation.external_id)
        ::Integrations::ProcessEventJob.perform_later(event.id)
        render json: { event_id: event.external_event_id, status: "accepted", duplicate: false, operation_id: operation.external_id }, status: :accepted
      end

      private

      def scoped_events
        integration_source ? integration_source.integration_events : IntegrationEvent.all
      end

      def event_payload(event)
        {
          event_id: event.external_event_id,
          event_type: event.event_type,
          schema_version: event.schema_version,
          source: event.integration_source.key,
          signature_status: event.signature_status,
          schema_status: event.schema_status,
          processing_status: event.processing_status,
          payload_digest: event.payload_digest,
          operation_id: event.current_operation&.external_id,
          occurred_at: event.occurred_at&.iso8601,
          received_at: event.received_at&.iso8601,
          error: {
            code: event.processing_error_code,
            message: event.processing_error_message
          }.compact
        }
      end

      def status_for(code)
        case code
        when ::Integrations::ErrorCatalog::CODES[:source_unknown] then :unauthorized
        when ::Integrations::ErrorCatalog::CODES[:source_suspended] then :forbidden
        when ::Integrations::ErrorCatalog::CODES[:event_id_conflict] then :conflict
        when ::Integrations::ErrorCatalog::CODES[:event_too_large] then :payload_too_large
        when ::Integrations::ErrorCatalog::CODES[:signature_invalid] then :unauthorized
        else :unprocessable_entity
        end
      end
    end
  end
end
