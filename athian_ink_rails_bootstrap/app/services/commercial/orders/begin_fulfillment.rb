module Commercial
  module Orders
    class BeginFulfillment
      def self.call(order, actor: nil, reason: nil, metadata: {})
        return order if order.status == "assembling"

        previous_status = order.status

        order.transaction do
          order.update!(status: "assembling")

          Commercial::OrderEvent.record_transition!(
            order,
            previous_status,
            "assembling",
            "begin_fulfillment",
            actor: actor,
            reason: reason || "Fulfillment workflow started",
            metadata: metadata
          )
        end

        order
      end
    end
  end
end
