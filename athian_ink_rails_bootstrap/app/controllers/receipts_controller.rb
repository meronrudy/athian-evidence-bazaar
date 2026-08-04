class ReceiptsController < ApplicationController
  def show
    @receipt = Receipt.includes(:evidence_items, :avsa).find(params[:id])
    @avsa = @receipt.avsa
    @parent_receipts = @receipt.parent_receipts
    @receipt_export = InkReceipts.export(receipt: InkProjection.receipt(@receipt))
    @verify_command = "ink verify receipt-#{@receipt.id}.json --policy trust-policy.json"
  end

  def download
    receipt = Receipt.includes(:evidence_items, :avsa).find(params[:id])
    send_data JSON.pretty_generate(InkReceipts.export(receipt: InkProjection.receipt(receipt))),
              filename: "#{receipt.receipt_type}-#{receipt.id}.json",
              type: "application/json",
              disposition: "attachment"
  end

  def verify
    receipt = Receipt.find(params[:id])
    result = InkVerifier.new(target: receipt).call
    receipt.avsa.verification_runs.create!(
      receipt: receipt,
      status: result.fetch(:status),
      verifier_mode: result.fetch(:mode),
      message: result.fetch(:message),
      checks: result.fetch(:checks),
      started_at: result.fetch(:started_at),
      completed_at: result.fetch(:completed_at)
    )
    redirect_to receipt, notice: "Local verification returned #{result.fetch(:status)}."
  end
end
