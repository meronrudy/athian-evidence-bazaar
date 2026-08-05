module Integrations
  class DeliveriesController < ApplicationController
    def index
      @deliveries = IntegrationDelivery.includes(:integration_webhook_endpoint)
                                       .order(created_at: :desc)
                                       .limit(100)
    end

    def show
      @delivery = IntegrationDelivery.includes(:integration_webhook_endpoint).find(params[:id])
    end

    def retry
      @delivery = IntegrationDelivery.find(params[:id])
      @delivery.update!(status: "pending", next_attempt_at: Time.current)
      Integrations::DeliverWebhookJob.perform_later(@delivery.id)
      redirect_to integrations_delivery_path(@delivery), notice: "Webhook delivery retry queued."
    end
  end
end
