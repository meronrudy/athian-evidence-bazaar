module Integrations
  class OutboxController < ApplicationController
    def index
      @outboxes = ReceiptOutbox.includes(:integration_event, :receipt)
                               .order(created_at: :desc)
                               .limit(100)
    end
  end
end
