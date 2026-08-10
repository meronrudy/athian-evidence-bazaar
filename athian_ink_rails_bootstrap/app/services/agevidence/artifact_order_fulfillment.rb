module Agevidence
  class ArtifactOrderFulfillment
    def initialize(order:)
      @order = order
    end

    def call
      raise "Artifact order must be paid before fulfillment" unless order.status == "paid"

      Commercial::Orders::BeginFulfillment.call(order)
      Commercial::Orders::Fulfill.call(order.reload)
    end

    private

    attr_reader :order
  end
end
