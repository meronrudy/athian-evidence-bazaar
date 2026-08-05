class CreateAgevidenceIntegrationBridge < ActiveRecord::Migration[7.1]
  def change
    create_table :agevidence_integration_sources do |t|
      t.references :developer_account, null: false, foreign_key: { to_table: :agevidence_developer_accounts }
      t.string :key, null: false
      t.string :name, null: false
      t.string :environment, null: false, default: "production"
      t.string :signing_algorithm, null: false, default: "hmac_sha256"
      t.text :verification_key
      t.string :verification_key_reference
      t.string :status, null: false, default: "active"
      t.datetime :last_event_at
      t.json :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_integration_sources, :key, unique: true

    create_table :agevidence_integration_events do |t|
      t.references :integration_source, null: false, foreign_key: { to_table: :agevidence_integration_sources }
      t.string :external_event_id, null: false
      t.string :operation_id, null: false
      t.string :event_type, null: false
      t.string :schema_version, null: false
      t.string :external_object_type, null: false
      t.string :external_object_id, null: false
      t.datetime :occurred_at, null: false
      t.datetime :received_at, null: false
      t.text :raw_envelope, null: false
      t.json :payload, null: false, default: {}
      t.json :correlation, null: false, default: {}
      t.string :payload_digest, null: false
      t.text :signature, null: false
      t.string :processing_status, null: false, default: "accepted"
      t.text :processing_error
      t.integer :attempt_count, null: false, default: 0
      t.datetime :last_attempt_at
      t.datetime :processed_at
      t.timestamps
    end
    add_index :agevidence_integration_events,
              %i[integration_source_id external_event_id],
              unique: true,
              name: "idx_agev_integration_events_source_event"
    add_index :agevidence_integration_events, :operation_id, unique: true
    add_index :agevidence_integration_events, %i[processing_status received_at], name: "idx_agev_integration_events_status"

    create_table :agevidence_external_object_mappings do |t|
      t.references :integration_source, null: false, foreign_key: { to_table: :agevidence_integration_sources }
      t.string :external_object_type, null: false
      t.string :external_object_id, null: false
      t.string :internal_record_type
      t.bigint :internal_record_id
      t.string :external_version
      t.references :last_integration_event, foreign_key: { to_table: :agevidence_integration_events }
      t.json :projection_payload, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_external_object_mappings,
              %i[integration_source_id external_object_type external_object_id],
              unique: true,
              name: "idx_agev_external_mapping_identity"
    add_index :agevidence_external_object_mappings,
              %i[internal_record_type internal_record_id],
              name: "idx_agev_external_mapping_internal"

    create_table :agevidence_receipt_outboxes do |t|
      t.references :integration_event, null: false, foreign_key: { to_table: :agevidence_integration_events }
      t.string :aggregate_type, null: false
      t.string :aggregate_id, null: false
      t.string :receipt_type, null: false
      t.string :schema_id, null: false
      t.json :canonical_payload, null: false, default: {}
      t.string :payload_digest
      t.string :idempotency_key, null: false
      t.string :status, null: false, default: "pending"
      t.references :receipt, foreign_key: true
      t.json :issued_receipt, null: false, default: {}
      t.json :verification_result, null: false, default: {}
      t.integer :attempt_count, null: false, default: 0
      t.text :processing_error
      t.datetime :processed_at
      t.timestamps
    end
    add_index :agevidence_receipt_outboxes, :idempotency_key, unique: true
    add_index :agevidence_receipt_outboxes, %i[status created_at], name: "idx_agev_receipt_outboxes_status"

    create_table :agevidence_integration_artifacts do |t|
      t.references :integration_source, null: false, foreign_key: { to_table: :agevidence_integration_sources }
      t.references :developer_project, foreign_key: { to_table: :agevidence_developer_projects }
      t.string :artifact_id, null: false
      t.string :external_project_id, null: false
      t.string :profile, null: false
      t.string :receipt_root, null: false
      t.string :verification_status, null: false
      t.string :policy_compatibility, null: false
      t.string :reliance_status, null: false, default: "not_yet_relied_upon"
      t.string :download_token, null: false
      t.json :manifest, null: false, default: {}
      t.datetime :compiled_at, null: false
      t.timestamps
    end
    add_index :agevidence_integration_artifacts, :artifact_id, unique: true
    add_index :agevidence_integration_artifacts, :download_token, unique: true
    add_index :agevidence_integration_artifacts,
              %i[integration_source_id external_project_id compiled_at],
              name: "idx_agev_integration_artifacts_project"

    create_table :agevidence_integration_webhook_endpoints do |t|
      t.references :integration_source, null: false, foreign_key: { to_table: :agevidence_integration_sources }
      t.string :url, null: false
      t.json :event_types, null: false, default: []
      t.string :status, null: false, default: "active"
      t.datetime :last_delivery_at
      t.integer :failure_count, null: false, default: 0
      t.timestamps
    end

    create_table :agevidence_integration_webhook_deliveries do |t|
      t.references :integration_webhook_endpoint, null: false, foreign_key: { to_table: :agevidence_integration_webhook_endpoints }
      t.references :integration_event, foreign_key: { to_table: :agevidence_integration_events }
      t.references :integration_artifact, foreign_key: { to_table: :agevidence_integration_artifacts }
      t.string :event_type, null: false
      t.string :idempotency_key, null: false
      t.json :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.integer :attempt_count, null: false, default: 0
      t.integer :response_code
      t.text :processing_error
      t.datetime :delivered_at
      t.timestamps
    end
    add_index :agevidence_integration_webhook_deliveries, :idempotency_key, unique: true, name: "idx_agev_webhook_delivery_idempotency"
    add_index :agevidence_integration_webhook_deliveries, %i[status created_at], name: "idx_agev_webhook_deliveries_status"
  end
end
