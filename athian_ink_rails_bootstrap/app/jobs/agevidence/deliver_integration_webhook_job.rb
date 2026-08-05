module Agevidence
  class DeliverIntegrationWebhookJob < ApplicationJob
    queue_as :integrations

    def perform(delivery_id)
      delivery = IntegrationWebhookDelivery.find(delivery_id)
      IntegrationWebhookDispatcher.new(delivery).deliver!
    end
  end
end
