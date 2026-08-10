module Commercial
  module Orders
    class Authorize
      def self.call(order, actor: nil, reason: nil, metadata: {})
        return order if order.status == "checkout_pending"
        raise "Artifact order cannot be authorized from #{order.status}" unless order.status == "quoted"

        previous_status = order.status
        order.previous_status = previous_status

        order.transaction do
          order.update!(status: "checkout_pending")

          Commercial::OrderEvent.record_transition!(
            order,
            previous_status,
            "checkout_pending",
            "authorize",
            actor: actor,
            reason: reason || "Payment authorized",
            metadata: metadata
          )
        end

        order
      end
    end
  end
end
