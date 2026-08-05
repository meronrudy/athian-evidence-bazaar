module Integrations
  class EventsController < ApplicationController
    def index
      @events = IntegrationEvent.includes(:integration_source)
                                .order(received_at: :desc)
      @events = @events.where(event_type: params[:event_type]) if params[:event_type].present?
      @events = @events.where(processing_status: params[:status]) if params[:status].present?
      @events = @events.where(integration_source_id: params[:source_id]) if params[:source_id].present?
      @events = @events.limit(100)
      @sources = IntegrationSource.order(:key)
    end

    def show
      @event = IntegrationEvent.includes(:integration_source, :integration_operations, :receipt_outboxes).find(params[:id])
      @mappings = ExternalObjectMapping.where(last_integration_event: @event).order(:external_object_type)
      @projections = @event.evidence_projections.order(:projection_type, :projection_version)
    end

    def replay
      @event = IntegrationEvent.find(params[:id])
      if params[:reason].blank?
        redirect_to integrations_event_path(@event), alert: "Replay requires an explicit reason."
        return
      end

      unless @event.replayable?
        redirect_to integrations_event_path(@event), alert: "This event is not eligible for replay."
        return
      end

      operation = @event.integration_operations.create!(
        operation_type: "event_replay",
        status: "pending",
        idempotency_key: "integration-event-replay:#{@event.integration_source.key}:#{@event.external_event_id}:#{Time.current.to_i}",
        result_json: { reason: params[:reason] }
      )
      @event.update!(processing_status: "accepted", operation_external_id: operation.external_id)
      Integrations::ProcessEventJob.perform_later(@event.id)
      redirect_to integrations_event_path(@event), notice: "Replay queued as #{operation.external_id}."
    end
  end
end
