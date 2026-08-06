module Commercial
  module Orders
    class Fulfill
      def self.call(order, actor: nil, reason: nil, metadata: {})
        return order if order.status == "fulfilled"

        previous_status = order.status

        order.transaction do
          order.update!(status: "fulfilled")

          Commercial::OrderEvent.record_transition!(
            order,
            previous_status,
            "fulfilled",
            "fulfill",
            actor: actor,
            reason: reason || "Artifact fulfillment completed",
            metadata: metadata
          )
        end

        order
      end
    end
  end
end
