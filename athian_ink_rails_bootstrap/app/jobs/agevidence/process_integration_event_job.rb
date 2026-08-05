module Agevidence
  class ProcessIntegrationEventJob < ApplicationJob
    queue_as :integrations

    def perform(event_id)
      event = IntegrationEvent.find(event_id)
      IntegrationEventProcessor.new(event).call
    end
  end
end
