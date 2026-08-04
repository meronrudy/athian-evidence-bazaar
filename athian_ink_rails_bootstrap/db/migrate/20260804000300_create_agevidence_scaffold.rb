class CreateAgevidenceScaffold < ActiveRecord::Migration[7.1]
  def change
    create_table :agevidence_developer_accounts do |t|
      t.string :name, null: false
      t.string :website
      t.string :funding_stage
      t.integer :capital_raised_cents, limit: 8, null: false, default: 0
      t.string :primary_segment
      t.string :headquarters
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :agevidence_developer_accounts, :name, unique: true

    create_table :agevidence_developer_projects do |t|
      t.references :developer_account, null: false, foreign_key: { to_table: :agevidence_developer_accounts }
      t.references :protocol, foreign_key: true
      t.references :avsa, foreign_key: true
      t.string :name, null: false
      t.string :project_type, null: false
      t.string :commercialization_stage
      t.text :target_claim
      t.string :protocol_status, null: false, default: "mapping"
      t.string :integration_status, null: false, default: "not_started"
      t.timestamps
    end

    create_table :agevidence_model_adapters do |t|
      t.string :adapter_id, null: false
      t.string :base_model_id, null: false
      t.string :provider
      t.string :license
      t.string :runtime
      t.string :weights_digest
      t.string :adapter_digest
      t.integer :context_limit
      t.boolean :multimodal, null: false, default: false
      t.string :status, null: false, default: "reference"
      t.timestamps
    end
    add_index :agevidence_model_adapters, :adapter_id, unique: true

    create_table :agevidence_model_runs do |t|
      t.references :developer_project, null: false, foreign_key: { to_table: :agevidence_developer_projects }
      t.references :model_adapter, null: false, foreign_key: { to_table: :agevidence_model_adapters }
      t.references :receipt, foreign_key: true
      t.string :task, null: false
      t.string :status, null: false, default: "queued"
      t.string :prompt_digest
      t.string :retrieval_digest
      t.json :input_manifest, null: false, default: {}
      t.json :normalized_output, null: false, default: {}
      t.string :output_digest
      t.json :runtime_metadata, null: false, default: {}
      t.datetime :started_at
      t.datetime :completed_at
      t.text :failure_reason
      t.timestamps
    end

    create_table :agevidence_evidence_candidates do |t|
      t.references :model_run, null: false, foreign_key: { to_table: :agevidence_model_runs }
      t.references :evidence_item, foreign_key: true
      t.references :receipt, foreign_key: true
      t.string :candidate_type, null: false
      t.text :claim_text, null: false
      t.json :source_references, null: false, default: []
      t.decimal :model_confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "review_required"
      t.text :review_notes
      t.string :reviewed_by
      t.datetime :reviewed_at
      t.timestamps
    end

    create_table :agevidence_evidence_gaps do |t|
      t.references :model_run, null: false, foreign_key: { to_table: :agevidence_model_runs }
      t.string :gap_type, null: false
      t.string :requirement, null: false
      t.text :description, null: false
      t.string :severity, null: false
      t.json :source_context, null: false, default: {}
      t.string :resolution_status, null: false, default: "open"
      t.timestamps
    end

    create_table :agevidence_review_decisions do |t|
      t.references :evidence_candidate, null: false, foreign_key: { to_table: :agevidence_evidence_candidates }
      t.references :receipt, foreign_key: true
      t.string :reviewer_role, null: false
      t.string :decision, null: false
      t.text :reason, null: false
      t.string :policy_version, null: false
      t.datetime :decided_at, null: false
      t.timestamps
    end

    create_table :agevidence_artifact_engagements do |t|
      t.references :developer_project, null: false, foreign_key: { to_table: :agevidence_developer_projects }
      t.references :evidence_bundle, foreign_key: true
      t.string :product_code, null: false
      t.string :pipeline_stage, null: false, default: "identified"
      t.string :billing_type, null: false, default: "fixed_fee"
      t.integer :list_price_cents, limit: 8, null: false, default: 0
      t.integer :quoted_price_cents, limit: 8, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.string :commercial_status, null: false, default: "illustrative"
      t.date :started_on
      t.date :completed_on
      t.timestamps
    end

    create_table :agevidence_reliance_events do |t|
      t.references :artifact_engagement, null: false, foreign_key: { to_table: :agevidence_artifact_engagements }
      t.references :evidence_bundle, null: false, foreign_key: true
      t.string :relying_party_name, null: false
      t.string :relying_party_role, null: false
      t.string :decision_type, null: false
      t.string :outcome, null: false
      t.string :evidence_bundle_digest
      t.datetime :occurred_at, null: false
      t.text :notes
      t.timestamps
    end

    add_column :evidence_bundles, :commercial_product_code, :string
    add_column :evidence_bundles, :artifact_version, :string
    add_column :evidence_bundles, :reliance_status, :string, null: false, default: "not_relied_on"
    add_column :evidence_bundles, :relying_party_count, :integer, null: false, default: 0
    add_column :evidence_bundles, :list_price_cents, :integer, limit: 8, null: false, default: 0
    add_column :evidence_bundles, :quoted_price_cents, :integer, limit: 8, null: false, default: 0
    add_column :evidence_bundles, :acceptance_receipt_id, :bigint
    add_column :evidence_bundles, :accepted_at, :datetime
    add_foreign_key :evidence_bundles, :receipts, column: :acceptance_receipt_id
  end
end
