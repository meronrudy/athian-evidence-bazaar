module Commercial
  module Orders
    class Fulfill
      def self.call(order, actor: nil, reason: nil, metadata: {})
        return order if order.status == "fulfilled"

        unless order.status == "assembling"
          raise "Artifact order must be assembling before fulfillment"
        end

        previous_status = order.status
        order.previous_status = previous_status

        order.transaction do
          # Ensure artifact engagement exists
          engagement = order.artifact_engagement || raise("Missing artifact engagement")
          bundle = Agevidence::ArtifactAssembler.new(engagement: engagement).call

          order.update!(status: "fulfilled", assembled_at: Time.current, artifact_engagement: engagement, evidence_bundle: bundle)
          project = order.developer_project
          order.metadata_json = order.metadata_json.merge(
            "receipt_root" => project.evidence_graph_root,
            "verification_command" => "ink verify-bundle #{bundle.artifact_filename}"
          )
          order.save!

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
