class CreateEvidencePlane < ActiveRecord::Migration[7.1]
  def change
    create_table :protocols do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :version, null: false
      t.string :governance_version, null: false
      t.string :status, null: false, default: "active"
      t.date :effective_on
      t.date :retired_on
      t.text :description
      t.timestamps
    end
    add_index :protocols, :code, unique: true

    create_table :avsas do |t|
      t.references :protocol, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :title, null: false
      t.string :producer_name, null: false
      t.string :intervention_provider
      t.string :vvb_name
      t.string :buyer_name
      t.string :status, null: false, default: "in_progress"
      t.decimal :verified_quantity, precision: 14, scale: 3, default: 0, null: false
      t.string :unit, null: false, default: "tCO2e"
      t.date :started_on
      t.string :reporting_period
      t.string :root_digest
      t.string :local_verification_status, null: false, default: "indeterminate"
      t.timestamps
    end
    add_index :avsas, :external_id, unique: true

    create_table :receipts do |t|
      t.references :avsa, null: false, foreign_key: true
      t.string :receipt_type, null: false
      t.string :title, null: false
      t.string :lifecycle_state, null: false, default: "draft"
      t.string :domain_state
      t.string :issuer_name
      t.string :signer_key_id
      t.string :schema_id
      t.string :schema_digest
      t.string :body_digest
      t.string :evidence_commitment
      t.string :policy_commitment
      t.string :trace_commitment
      t.integer :sequence, null: false
      t.json :parent_receipt_ids, null: false, default: []
      t.text :canonical_encoding_hex
      t.string :integrity_status, null: false, default: "indeterminate"
      t.datetime :signed_at
      t.datetime :sealed_at
      t.timestamps
    end
    add_index :receipts, %i[avsa_id sequence], unique: true
    add_index :receipts, :body_digest, unique: true

    create_table :evidence_items do |t|
      t.references :receipt, null: false, foreign_key: true
      t.string :name, null: false
      t.string :evidence_type, null: false
      t.string :source_system
      t.string :commitment, null: false
      t.string :disclosure_status, null: false, default: "restricted"
      t.boolean :required, null: false, default: true
      t.string :status, null: false, default: "present"
      t.datetime :captured_at
      t.json :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :claim_groups do |t|
      t.references :avsa, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :verified_total, precision: 14, scale: 3, null: false
      t.string :unit, null: false, default: "tCO2e"
      t.decimal :aggregate_cap_percent, precision: 5, scale: 2, null: false, default: 100
      t.string :finalization_status, null: false, default: "draft"
      t.string :prior_claim_check_status, null: false, default: "pending"
      t.timestamps
    end

    create_table :claim_shares do |t|
      t.references :claim_group, null: false, foreign_key: true
      t.string :claimant_name, null: false
      t.string :claimant_role, null: false
      t.decimal :share_percent, precision: 5, scale: 2, null: false
      t.decimal :contribution_amount, precision: 12, scale: 2, null: false, default: 0
      t.string :inventory_category
      t.string :contract_right_digest
      t.string :status, null: false, default: "proposed"
      t.timestamps
    end

    create_table :verification_runs do |t|
      t.references :avsa, null: false, foreign_key: true
      t.references :receipt, foreign_key: true
      t.string :status, null: false
      t.string :verifier_mode, null: false
      t.text :message
      t.json :checks, null: false, default: []
      t.datetime :started_at, null: false
      t.datetime :completed_at, null: false
      t.timestamps
    end

    create_table :verification_exceptions do |t|
      t.references :avsa, null: false, foreign_key: true
      t.references :receipt, foreign_key: true
      t.string :code, null: false
      t.string :severity, null: false
      t.string :status, null: false, default: "open"
      t.string :materiality
      t.text :description, null: false
      t.string :owner
      t.date :due_on
      t.timestamps
    end

    create_table :producer_payments do |t|
      t.references :avsa, null: false, foreign_key: true
      t.string :producer_name, null: false
      t.decimal :gross_amount, precision: 12, scale: 2, null: false
      t.decimal :verification_deduction, precision: 12, scale: 2, null: false, default: 0
      t.decimal :platform_deduction, precision: 12, scale: 2, null: false, default: 0
      t.decimal :other_deductions, precision: 12, scale: 2, null: false, default: 0
      t.decimal :net_amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false, default: "USD"
      t.string :status, null: false, default: "pending"
      t.string :remittance_reference
      t.datetime :paid_at
      t.timestamps
    end
  end
end
