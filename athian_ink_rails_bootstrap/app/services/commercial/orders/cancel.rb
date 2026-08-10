module Commercial
  module Orders
    class Cancel
      def self.call(order, actor: nil, reason: nil, metadata: {})
        return order if order.status == "canceled"

        unless %w[quoted checkout_pending paid].include?(order.status)
          raise "Order can only be canceled from quoted, checkout_pending, or paid status"
        end

        previous_status = order.status
        order.previous_status = previous_status

        order.transaction do
          order.update!(status: "canceled")

          Commercial::OrderEvent.record_transition!(
            order,
            previous_status,
            "canceled",
            "cancel",
            actor: actor,
            reason: reason || "Order canceled",
            metadata: metadata
          )
        end

        order
      end
    end
  end
end
