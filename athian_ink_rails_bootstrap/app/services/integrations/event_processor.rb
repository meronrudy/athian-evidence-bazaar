module Integrations
  class EventProcessor
    def initialize(event:)
      @event = event
      @operation = event.current_operation
    end

    def call
      return unless event.accepted_for_processing? || event.processing_status == "failed"

      result = nil
      ActiveRecord::Base.transaction do
        event.lock!
        next if event.processing_status == "processed"

        operation.update!(status: "running", started_at: Time.current) if operation
        event.update!(processing_status: "processing", attempt_count: event.attempt_count + 1)
        result = EventRegistry.handler_for(event.event_type).new(event: event).call
        event.update!(processing_status: "processed", processed_at: Time.current, processing_error_code: nil, processing_error_message: nil)
        operation&.succeed!(
          projections: result.projections.map(&:id),
          receipt_requests: result.receipt_requests.map(&:id),
          external_mappings: result.external_mappings.map(&:id),
          warnings: result.warnings
        )
      end

      Array(result&.receipt_requests).each do |outbox|
        Receipts::ProcessOutboxJob.perform_later(outbox.id)
      end
    rescue StandardError => e
      event.update!(
        processing_status: "failed",
        processing_error_code: "EVENT_PROCESSING_FAILED",
        processing_error_message: e.message
      )
      operation&.fail!(code: "EVENT_PROCESSING_FAILED", message: e.message)
    end

    private

    attr_reader :event, :operation
  end
end
