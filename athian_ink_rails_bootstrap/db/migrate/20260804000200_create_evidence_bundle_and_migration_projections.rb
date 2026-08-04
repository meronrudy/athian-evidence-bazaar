class CreateEvidenceBundleAndMigrationProjections < ActiveRecord::Migration[7.1]
  def change
    add_column :avsas, :methodology_name, :string
    add_column :avsas, :methodology_version, :string

    add_column :claim_groups, :retirement_status, :string, null: false, default: "valid"
    add_column :claim_groups, :exclusivity_status, :string, null: false, default: "valid"

    create_table :evidence_bundles do |t|
      t.references :avsa, null: false, foreign_key: true
      t.string :bundle_type, null: false
      t.string :name, null: false
      t.string :audience
      t.string :status, null: false, default: "generated"
      t.string :artifact_filename, null: false
      t.string :artifact_path
      t.string :verification_status, null: false, default: "indeterminate"
      t.text :problem
      t.json :manifest, null: false, default: {}
      t.datetime :generated_at, null: false
      t.timestamps
    end
    add_index :evidence_bundles, %i[avsa_id bundle_type generated_at], name: "idx_evidence_bundles_lookup"

    create_table :methodology_migrations do |t|
      t.references :avsa, null: false, foreign_key: true
      t.references :delta_receipt, foreign_key: { to_table: :receipts }
      t.string :old_methodology, null: false
      t.string :old_version, null: false
      t.string :new_methodology, null: false
      t.string :new_version, null: false
      t.string :status, null: false, default: "pending"
      t.decimal :affected_credits, precision: 14, scale: 3, null: false, default: 0
      t.text :impact_summary
      t.json :recalculation_payload, null: false, default: {}
      t.datetime :appended_at
      t.timestamps
    end
  end
end
