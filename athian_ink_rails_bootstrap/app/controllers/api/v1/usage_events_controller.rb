module Api
  module V1
    class UsageEventsController < BaseController
      before_action -> { require_scope!("usage:write") }, only: :create
      before_action -> { require_scope!("usage:read") }, only: :index

      def create
        key = idempotency_key!
        event = Agevidence::UsageEvent.find_or_initialize_by(developer_account: current_developer_account, idempotency_key: key)
        if event.persisted?
          return render json: { data: serialize(event) }, status: :ok
        end

        event.assign_attributes(
          api_client: current_api_client,
          event_type: usage_params.fetch(:event_type),
          product_code: usage_params.fetch(:product_code),
          quantity: usage_params.fetch(:quantity, 1),
          unit: usage_params.fetch(:unit),
          occurred_at: usage_params[:occurred_at].presence || Time.current,
          metadata: usage_params.fetch(:metadata, {}).to_h
        )
        event.save!
        render json: { data: serialize(event) }, status: :created
      end

      def index
        start_at = params[:start_at].present? ? Time.zone.parse(params[:start_at]) : Time.current.beginning_of_month
        end_at = params[:end_at].present? ? Time.zone.parse(params[:end_at]) : Time.current
        events = current_developer_account.usage_events.during(start_at..end_at)
        grouped = events.group(:product_code, :unit).sum(:quantity)

        render json: {
          data: {
            start_at: start_at,
            end_at: end_at,
            totals: grouped.map { |(product_code, unit), quantity| { product_code: product_code, unit: unit, quantity: quantity } }
          }
        }
      end

      private

      def usage_params
        params.require(:usage_event).permit(:event_type, :product_code, :quantity, :unit, :occurred_at, metadata: {})
      end

      def serialize(event)
        {
          id: event.id,
          event_type: event.event_type,
          product_code: event.product_code,
          quantity: event.quantity,
          unit: event.unit,
          occurred_at: event.occurred_at,
          created_at: event.created_at
        }
      end
    end
  end
end
