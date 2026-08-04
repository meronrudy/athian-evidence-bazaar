class ProducerPaymentsController < ApplicationController
  def index
    @payments = ProducerPayment.includes(avsa: :receipts).order(created_at: :desc)
    @traceability_rate = if @payments.empty?
                           0
                         else
                           linked = @payments.count { |payment| payment.avsa.receipts.any? { |r| r.receipt_type == "producer_payment_receipt" } }
                           (linked.to_f / @payments.size * 100).round
                         end
  end

  def show
    @payment = ProducerPayment.includes(avsa: :receipts).find(params[:id])
  end
end
