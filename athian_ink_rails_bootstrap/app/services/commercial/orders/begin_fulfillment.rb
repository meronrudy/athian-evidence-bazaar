module Commercial
  module Orders
    class BeginFulfillment
      def self.call(order, actor: nil, reason: nil, metadata: {})
        return order if order.status == "assembling"

        unless order.status == "paid"
          raise "Artifact order must be paid before beginning fulfillment"
        end

        previous_status = order.status
        order.previous_status = previous_status

        order.transaction do
          # Ensure lightweight AVSA scaffold exists
          ensure_lightweight_avsa!(order.developer_project)

          # Ensure artifact engagement exists
          engagement = ensure_engagement!(order)

          order.update!(status: "assembling", artifact_engagement: engagement)

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

      private

      def self.ensure_lightweight_avsa!(project)
        return project.avsa if project.avsa

        protocol = project.protocol || Protocol.find_or_create_by!(code: "ATH-DEVELOPER-OS") do |record|
          record.name = "Athian Developer OS Projection Protocol"
          record.version = "v1"
          record.governance_version = "ATH-DEVELOPER-OS-2026.1"
          record.status = "active"
          record.description = "Lightweight scaffold protocol used only to anchor self-service artifact receipts."
        end

        avsa = Avsa.create!(
          protocol: protocol,
          external_id: "AVSA-DEVELOPER-OS-#{project.id}",
          title: project.name,
          producer_name: project.developer_account.name,
          status: "in_progress",
          verified_quantity: 0,
          unit: "tCO2e",
          local_verification_status: "indeterminate",
          methodology_name: protocol.name,
          methodology_version: protocol.version
        )
        project.update!(avsa: avsa, protocol: protocol)
        avsa
      end

      def self.ensure_engagement!(order)
        return order.artifact_engagement if order.artifact_engagement

        product = Agevidence::ProductCatalog.fetch(order.product_code)
        order.developer_project.artifact_engagements.create!(
          product_code: order.product_code,
          pipeline_stage: "scoped",
          billing_type: product.fetch("billing_type"),
          list_price_cents: product.fetch("base_planning_price_cents"),
          quoted_price_cents: order.amount_cents,
          currency: order.currency,
          commercial_status: "proposed",
          started_on: Date.current
        )
      end
    end
  end
end
