module Receipts
  class ProcessOutboxJob < ApplicationJob
    queue_as :default

    def perform(receipt_outbox_id)
      Agevidence::ReceiptOutboxProcessor.new(receipt_outbox: ReceiptOutbox.find(receipt_outbox_id)).call
    end
  end
end
