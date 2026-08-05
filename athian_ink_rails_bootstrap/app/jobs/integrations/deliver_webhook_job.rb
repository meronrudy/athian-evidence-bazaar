module Integrations
  class DeliverWebhookJob < ApplicationJob
    queue_as :default

    def perform(integration_delivery_id)
      WebhookDeliveryProcessor.new(delivery: IntegrationDelivery.find(integration_delivery_id)).call
    end
  end
end
