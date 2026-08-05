class CreateIntegrationEventInbox < ActiveRecord::Migration[7.1]
  def change
    create_table :integration_sources do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :environment
      t.string :status, null: false, default: "active"
      t.string :signature_algorithm, null: false, default: "hmac_sha256"
      t.text :verification_secret_ciphertext
      t.text :verification_public_key
      t.datetime :last_event_at
      t.json :allowed_event_types, null: false, default: []
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :integration_sources, :key, unique: true
    add_index :integration_sources, :status

    create_table :integration_events do |t|
      t.references :integration_source, null: false, foreign_key: true
      t.string :external_event_id, null: false
      t.string :event_type, null: false
      t.string :schema_version, null: false
      t.string :external_object_type
      t.string :external_object_id
      t.datetime :occurred_at
      t.datetime :received_at, null: false
      t.text :raw_payload_json, null: false
      t.text :canonical_payload_json, null: false
      t.string :payload_digest, null: false
      t.string :provided_digest
      t.text :signature
      t.string :signature_algorithm
      t.string :signature_status, null: false, default: "unchecked"
      t.string :schema_status, null: false, default: "unchecked"
      t.string :processing_status, null: false, default: "received"
      t.string :processing_error_code
      t.text :processing_error_message
      t.integer :attempt_count, null: false, default: 0
      t.datetime :processed_at
      t.string :operation_external_id
      t.string :supersedes_event_id
      t.json :correlation_json, null: false, default: {}
      t.timestamps
    end
    add_index :integration_events,
              %i[integration_source_id external_event_id],
              unique: true,
              name: "idx_integration_events_source_external_id"
    add_index :integration_events, :payload_digest
    add_index :integration_events, :processing_status
    add_index :integration_events, %i[event_type occurred_at]

    create_table :integration_operations do |t|
      t.references :integration_event, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :operation_type, null: false
      t.string :status, null: false, default: "pending"
      t.string :idempotency_key, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.string :error_code
      t.text :error_message
      t.json :result_json, null: false, default: {}
      t.timestamps
    end
    add_index :integration_operations, :external_id, unique: true
    add_index :integration_operations, :idempotency_key, unique: true
    add_index :integration_operations, :status

    create_table :external_object_mappings do |t|
      t.references :integration_source, null: false, foreign_key: true
      t.string :external_object_type, null: false
      t.string :external_object_id, null: false
      t.string :internal_record_type, null: false
      t.bigint :internal_record_id
      t.string :external_version
      t.references :last_integration_event, foreign_key: { to_table: :integration_events }
      t.datetime :first_seen_at, null: false
      t.datetime :last_seen_at, null: false
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :external_object_mappings,
              %i[integration_source_id external_object_type external_object_id internal_record_type],
              unique: true,
              name: "idx_external_object_mappings_identity"
    add_index :external_object_mappings,
              %i[internal_record_type internal_record_id],
              name: "idx_external_object_mappings_internal"

    create_table :evidence_projections do |t|
      t.string :projection_type, null: false
      t.string :external_project_id
      t.string :external_subject_type
      t.string :external_subject_id
      t.string :current_state, null: false, default: "indeterminate"
      t.references :source_event, null: false, foreign_key: { to_table: :integration_events }
      t.string :source_event_digest, null: false
      t.integer :projection_version, null: false, default: 1
      t.json :data_json, null: false, default: {}
      t.datetime :occurred_at
      t.datetime :projected_at, null: false
      t.references :supersedes_projection, foreign_key: { to_table: :evidence_projections }
      t.timestamps
    end
    add_index :evidence_projections,
              %i[projection_type external_project_id external_subject_id projection_version],
              name: "idx_evidence_projections_lookup"
    add_index :evidence_projections, :current_state

    create_table :receipt_outboxes do |t|
      t.references :integration_event, null: false, foreign_key: true
      t.string :aggregate_type, null: false
      t.bigint :aggregate_id
      t.string :receipt_type, null: false
      t.string :schema_id, null: false
      t.string :schema_version, null: false, default: "1.0.0"
      t.json :canonical_payload_json, null: false, default: {}
      t.string :payload_digest, null: false
      t.string :idempotency_key, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempt_count, null: false, default: 0
      t.references :receipt, foreign_key: true
      t.string :receipt_digest
      t.string :verification_status
      t.json :verification_result_json, null: false, default: {}
      t.string :last_error_code
      t.text :last_error_message
      t.datetime :issued_at
      t.timestamps
    end
    add_index :receipt_outboxes, :idempotency_key, unique: true
    add_index :receipt_outboxes, :status
    add_index :receipt_outboxes, %i[aggregate_type aggregate_id]

    create_table :integration_webhook_endpoints do |t|
      t.references :integration_source, null: false, foreign_key: true
      t.string :url, null: false
      t.string :status, null: false, default: "active"
      t.text :signing_secret_ciphertext
      t.json :subscribed_event_types, null: false, default: []
      t.datetime :last_success_at
      t.datetime :last_failure_at
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :integration_webhook_endpoints, :status

    create_table :integration_deliveries do |t|
      t.references :integration_webhook_endpoint, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :external_id, null: false
      t.json :payload_json, null: false, default: {}
      t.string :payload_digest
      t.string :idempotency_key, null: false
      t.text :signature
      t.string :status, null: false, default: "pending"
      t.integer :attempt_count, null: false, default: 0
      t.integer :response_status
      t.text :response_body_excerpt
      t.datetime :next_attempt_at
      t.datetime :delivered_at
      t.text :last_error
      t.timestamps
    end
    add_index :integration_deliveries, :external_id, unique: true
    add_index :integration_deliveries, :idempotency_key, unique: true
    add_index :integration_deliveries, :status
    add_index :integration_deliveries, :next_attempt_at
  end
end
