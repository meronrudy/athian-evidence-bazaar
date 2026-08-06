class CreateCommercialOrderEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :commercial_order_events do |t|
      t.references :order, null: false, foreign_key: { to_table: :agevidence_artifact_orders }
      t.string :from_state, null: false
      t.string :to_state, null: false
      t.string :event_type, null: false
      t.string :actor_type
      t.integer :actor_id
      t.text :reason
      t.jsonb :metadata_json, default: {}
      t.datetime :occurred_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :commercial_order_events, [:order_id, :occurred_at]
    add_index :commercial_order_events, :event_type
  end
end
