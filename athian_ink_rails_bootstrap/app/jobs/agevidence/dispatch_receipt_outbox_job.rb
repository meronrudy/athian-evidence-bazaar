module Agevidence
  class DispatchReceiptOutboxJob < ApplicationJob
    queue_as :receipts

    def perform(outbox_id)
      outbox = ReceiptOutbox.find(outbox_id)
      ReceiptOutboxDispatcher.new(outbox).call
    end
  end
end
