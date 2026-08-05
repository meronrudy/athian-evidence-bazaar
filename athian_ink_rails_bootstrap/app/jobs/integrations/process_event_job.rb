module Integrations
  class ProcessEventJob < ApplicationJob
    queue_as :default

    def perform(integration_event_id)
      event = IntegrationEvent.find(integration_event_id)
      EventProcessor.new(event: event).call
    end
  end
end
