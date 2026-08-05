module Campaign
  class DeliverConnectorOutboxJob < ApplicationJob
    queue_as :default

    def perform(outbox_id)
      outbox = Campaign::ConnectorOutbox.find(outbox_id)
      Campaign::ConnectorOutboxDispatcher.new(outbox: outbox).call
    end
  end
end
