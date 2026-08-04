class AvsasController < ApplicationController
  def show
    @avsa = Avsa.includes(receipts: :evidence_items).find(params[:id])
    @receipts = @avsa.receipts.core_chain
    @appendix_receipts = @avsa.receipts.append_only
    @open_exceptions = @avsa.verification_exceptions.where(status: "open")
    @receipt_graph = InkReceipts.graph(receipts: @avsa.receipts.map { |receipt| InkProjection.receipt(receipt) })
  end
end
