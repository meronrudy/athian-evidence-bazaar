module Integrations
  class DeadLetterController < ApplicationController
    def index
      @events = IntegrationEvent.where(processing_status: "dead_letter").order(received_at: :desc)
      @outboxes = ReceiptOutbox.where(status: "dead_letter").order(updated_at: :desc)
      @deliveries = IntegrationDelivery.where(status: "dead_letter").order(updated_at: :desc)
    end
  end
end
