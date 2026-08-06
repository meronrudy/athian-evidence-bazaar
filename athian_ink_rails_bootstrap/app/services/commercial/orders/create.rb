module Commercial
  module Orders
    class Create
      def self.call(developer_project, pricing_quote, attrs = {})
        order = Agevidence::ArtifactOrder.new(
          developer_project: developer_project,
          pricing_quote: pricing_quote,
          product_code: pricing_quote.product_code,
          amount_cents: pricing_quote.amount_cents,
          currency: pricing_quote.currency || "USD",
          status: "quoted",
          **attrs
        )

        if order.save
          Commercial::OrderEvent.record_transition!(
            order,
            "none",
            "quoted",
            "create",
            reason: "Order created from quote"
          )
          order
        else
          raise ActiveRecord::RecordInvalid.new(order)
        end
      end
    end
  end
end
