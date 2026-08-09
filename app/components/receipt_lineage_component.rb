class ReceiptLineageComponent < ApplicationComponent
  def initialize(project:)
    @project = project
    @receipts = project.receipts.ordered
  end

  def call
    div class: 'receipt-lineage' do
      h3 'Receipt Lineage'
      
      if @receipts.empty?
        p 'No receipts found for this project.'
      else
        div class: 'receipt-timeline' do
          @receipts.each do |receipt|
            render ReceiptEntryComponent.new(receipt: receipt)
          end
        end
      end

      div class: 'receipt-actions' do
        button class: 'btn btn-primary', data: { action: 'click->receipt-lineage#upload' } do
          'Upload Receipt'
        end
        button class: 'btn btn-outline', data: { action: 'click->receipt-lineage#verify' } do
          'Verify Receipt'
        end
      end
    end
  end
end