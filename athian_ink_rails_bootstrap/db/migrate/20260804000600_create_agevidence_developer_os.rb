class CreateAgevidenceDeveloperOs < ActiveRecord::Migration[7.1]
  def change
    create_table :agevidence_source_records do |t|
      t.references :developer_project, null: false, foreign_key: { to_table: :agevidence_developer_projects }
      t.references :source_event, foreign_key: { to_table: :integration_events }
      t.references :evidence_projection, foreign_key: true
      t.references :receipt, foreign_key: true
      t.string :document_id, null: false
      t.string :evidence_type, null: false
      t.string :evidence_class, null: false, default: "source_record"
      t.string :source_system
      t.string :controlled_uri, null: false
      t.string :commitment, null: false
      t.string :disclosure_status, null: false, default: "restricted"
      t.string :status, null: false, default: "referenced"
      t.datetime :captured_at
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_source_records, %i[developer_project_id document_id], unique: true, name: "idx_agev_source_records_project_document"
    add_index :agevidence_source_records, :status

    create_table :agevidence_pricing_quotes do |t|
      t.references :developer_project, null: false, foreign_key: { to_table: :agevidence_developer_projects }
      t.string :external_id, null: false
      t.string :product_code, null: false
      t.string :pricing_version, null: false
      t.string :currency, null: false, default: "USD"
      t.integer :amount_cents, limit: 8, null: false, default: 0
      t.json :input_json, null: false, default: {}
      t.json :breakdown_json, null: false, default: []
      t.string :status, null: false, default: "quoted"
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.timestamps
    end
    add_index :agevidence_pricing_quotes, :external_id, unique: true
    add_index :agevidence_pricing_quotes, %i[developer_project_id product_code status], name: "idx_agev_pricing_quotes_project"

    create_table :agevidence_artifact_orders do |t|
      t.references :developer_project, null: false, foreign_key: { to_table: :agevidence_developer_projects }
      t.references :pricing_quote, null: false, foreign_key: { to_table: :agevidence_pricing_quotes }
      t.references :artifact_engagement, foreign_key: { to_table: :agevidence_artifact_engagements }
      t.references :evidence_bundle, foreign_key: true
      t.string :external_id, null: false
      t.string :product_code, null: false
      t.string :status, null: false, default: "quoted"
      t.integer :amount_cents, limit: 8, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.string :checkout_url
      t.datetime :checkout_completed_at
      t.datetime :assembled_at
      t.datetime :canceled_at
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_artifact_orders, :external_id, unique: true
    add_index :agevidence_artifact_orders, %i[developer_project_id status], name: "idx_agev_artifact_orders_project"
  end
end
