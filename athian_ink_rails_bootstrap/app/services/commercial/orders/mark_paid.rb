module Commercial
  module Orders
    class MarkPaid
      def self.call(order, actor: nil, reason: nil, metadata: {})
        return order if order.status == "paid"

        previous_status = order.status

        order.transaction do
          order.update!(
            status: "paid",
            checkout_completed_at: Time.current
          )

          Commercial::OrderEvent.record_transition!(
            order,
            previous_status,
            "paid",
            "mark_paid",
            actor: actor,
            reason: reason || "Payment confirmed via provider",
            metadata: metadata
          )
        end

        order
      end
    end
  end
end
