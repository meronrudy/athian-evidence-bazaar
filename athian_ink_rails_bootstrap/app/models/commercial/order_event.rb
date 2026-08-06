module Commercial
  class OrderEvent < ApplicationRecord
    self.table_name = "commercial_order_events"

    belongs_to :order, class_name: "Agevidence::ArtifactOrder"

    validates :from_state, :to_state, :event_type, :occurred_at, presence: true
    validates :event_type, inclusion: { in: %w[create authorize mark_paid begin_fulfillment mark_verification_pending fulfill cancel fail] }

    scope :for_order, ->(order) { where(order: order).order(occurred_at: :asc) }

    def self.record_transition!(order, from_state, to_state, event_type, actor: nil, reason: nil, metadata: {})
      create!(
        order: order,
        from_state: from_state.to_s,
        to_state: to_state.to_s,
        event_type: event_type.to_s,
        actor_type: actor&.class&.name,
        actor_id: actor&.id,
        reason: reason,
        metadata_json: metadata,
        occurred_at: Time.current
      )
    end
  end
end
