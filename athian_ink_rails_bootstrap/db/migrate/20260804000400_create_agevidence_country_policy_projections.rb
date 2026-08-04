class CreateAgevidenceCountryPolicyProjections < ActiveRecord::Migration[7.1]
  def change
    create_table :agevidence_country_programs do |t|
      t.string :name, null: false
      t.string :country_code, null: false
      t.string :program_type
      t.string :authority_name
      t.string :status, null: false, default: "scaffold"
      t.text :description
      t.timestamps
    end
    add_index :agevidence_country_programs, %i[country_code name], unique: true

    create_table :agevidence_country_methods do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :method_id, null: false
      t.string :name, null: false
      t.string :authority_name
      t.string :status, null: false, default: "scaffold"
      t.timestamps
    end
    add_index :agevidence_country_methods, %i[country_program_id method_id], unique: true, name: "idx_agev_country_methods"

    create_table :agevidence_country_method_versions do |t|
      t.references :country_method, null: false, foreign_key: { to_table: :agevidence_country_methods }
      t.string :version, null: false
      t.string :authority_version
      t.string :status, null: false, default: "active"
      t.date :effective_on
      t.date :retired_on
      t.json :method_payload, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_country_method_versions, %i[country_method_id version], unique: true, name: "idx_agev_method_versions"

    create_table :agevidence_country_claim_policies do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :policy_id, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "active"
      t.json :policy_payload, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_country_claim_policies, %i[country_program_id policy_id version], unique: true, name: "idx_agev_claim_policies"

    create_table :agevidence_country_verification_profiles do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :profile_id, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "active"
      t.json :profile_payload, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_country_verification_profiles, %i[country_program_id profile_id version], unique: true, name: "idx_agev_verification_profiles"

    create_table :agevidence_country_data_policies do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :policy_id, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "active"
      t.json :policy_payload, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_country_data_policies, %i[country_program_id policy_id version], unique: true, name: "idx_agev_data_policies"

    create_table :agevidence_country_adapters do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.references :country_method_version, null: false, foreign_key: { to_table: :agevidence_country_method_versions }
      t.references :country_claim_policy, foreign_key: { to_table: :agevidence_country_claim_policies }
      t.references :country_verification_profile, foreign_key: { to_table: :agevidence_country_verification_profiles }
      t.references :country_data_policy, foreign_key: { to_table: :agevidence_country_data_policies }
      t.references :commitment_receipt, foreign_key: { to_table: :receipts }
      t.string :adapter_id, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "scaffold"
      t.string :country_code, null: false
      t.json :manifest, null: false, default: {}
      t.datetime :activated_at
      t.timestamps
    end
    add_index :agevidence_country_adapters, %i[adapter_id version], unique: true, name: "idx_agev_country_adapters"

    create_table :agevidence_country_institutions do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :name, null: false
      t.string :institution_role, null: false
      t.string :status, null: false, default: "scaffold"
      t.timestamps
    end

    create_table :agevidence_country_pilots do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :name, null: false
      t.string :status, null: false, default: "scaffold"
      t.date :started_on
      t.date :ended_on
      t.text :description
      t.timestamps
    end

    create_table :agevidence_country_registries do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :name, null: false
      t.string :registry_code
      t.string :status, null: false, default: "scaffold"
      t.json :mapping_payload, null: false, default: {}
      t.timestamps
    end

    create_table :agevidence_country_determinations do |t|
      t.references :developer_project, null: false, foreign_key: { to_table: :agevidence_developer_projects }
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.references :country_adapter, null: false, foreign_key: { to_table: :agevidence_country_adapters }
      t.references :country_method_version, null: false, foreign_key: { to_table: :agevidence_country_method_versions }
      t.references :supersedes, foreign_key: { to_table: :agevidence_country_determinations }
      t.references :receipt, foreign_key: true
      t.string :status, null: false
      t.json :normalized_result, null: false, default: {}
      t.string :result_digest
      t.datetime :evaluated_at, null: false
      t.timestamps
    end
    add_index :agevidence_country_determinations, %i[developer_project_id country_adapter_id evaluated_at], name: "idx_agev_country_determinations"

    add_reference :agevidence_developer_projects, :country_program, foreign_key: { to_table: :agevidence_country_programs }
    add_column :agevidence_developer_projects, :primary_country_program_id, :bigint
    add_column :agevidence_developer_projects, :country_context, :json, null: false, default: {}
    add_foreign_key :agevidence_developer_projects, :agevidence_country_programs, column: :primary_country_program_id

    add_reference :agevidence_model_runs, :country_adapter, foreign_key: { to_table: :agevidence_country_adapters }
    add_reference :evidence_bundles, :country_adapter, foreign_key: { to_table: :agevidence_country_adapters }
    add_reference :evidence_bundles, :country_claim_policy, foreign_key: { to_table: :agevidence_country_claim_policies }
    add_reference :evidence_bundles, :country_verification_profile, foreign_key: { to_table: :agevidence_country_verification_profiles }
    add_reference :evidence_bundles, :country_data_policy, foreign_key: { to_table: :agevidence_country_data_policies }
    add_reference :evidence_bundles, :country_determination, foreign_key: { to_table: :agevidence_country_determinations }
  end
end
