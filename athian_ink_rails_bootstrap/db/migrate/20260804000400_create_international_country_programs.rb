class CreateInternationalCountryPrograms < ActiveRecord::Migration[7.1]
  def change
    create_table :agevidence_country_programs do |t|
      t.string :code, null: false
      t.string :country_name, null: false
      t.string :program_name, null: false
      t.integer :priority, null: false
      t.string :phase, null: false
      t.string :status, null: false, default: "research"
      t.string :currency, null: false, default: "USD"
      t.json :language_codes, null: false, default: []
      t.text :market_condition, null: false
      t.text :developer_proposition, null: false
      t.json :launch_pattern, null: false, default: {}
      t.json :target_segments, null: false, default: []
      t.json :institutional_triggers, null: false, default: []
      t.json :premium_products, null: false, default: []
      t.json :localization_requirements, null: false, default: []
      t.json :source_basis, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_country_programs, :code, unique: true
    add_index :agevidence_country_programs, :priority, unique: true

    create_table :agevidence_country_methods do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :code, null: false
      t.string :name, null: false
      t.string :authority, null: false
      t.text :scope, null: false
      t.string :status, null: false, default: "research"
      t.timestamps
    end
    add_index :agevidence_country_methods, [:country_program_id, :code], unique: true,
      name: "idx_country_methods_program_code"

    create_table :agevidence_country_method_versions do |t|
      t.references :country_method, null: false, foreign_key: { to_table: :agevidence_country_methods }
      t.string :version, null: false
      t.string :status, null: false, default: "research"
      t.date :effective_on
      t.json :eligible_interventions, null: false, default: []
      t.json :excluded_contexts, null: false, default: []
      t.json :monitoring_requirements, null: false, default: []
      t.json :accepted_emissions_factors, null: false, default: []
      t.text :additionality_treatment
      t.text :grandfathering_rules
      t.string :source_url
      t.timestamps
    end
    add_index :agevidence_country_method_versions, [:country_method_id, :version], unique: true,
      name: "idx_country_method_versions_method_version"

    create_table :agevidence_country_adapters do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.references :country_method_version, foreign_key: { to_table: :agevidence_country_method_versions }
      t.string :adapter_id, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "research"
      t.json :accepted_terminology, null: false, default: {}
      t.json :eligibility_rules, null: false, default: {}
      t.json :registry_mapping, null: false, default: {}
      t.json :claim_rules, null: false, default: {}
      t.json :producer_rights, null: false, default: []
      t.json :data_requirements, null: false, default: {}
      t.json :limitations, null: false, default: []
      t.timestamps
    end
    add_index :agevidence_country_adapters, :adapter_id, unique: true

    create_table :agevidence_country_institutions do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :name, null: false
      t.string :institution_type, null: false
      t.string :seat, null: false
      t.string :status, null: false, default: "proposed"
      t.text :authority_scope
      t.string :website
      t.timestamps
    end
    add_index :agevidence_country_institutions, [:country_program_id, :name], unique: true,
      name: "idx_country_institutions_program_name"

    create_table :agevidence_country_pilots do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.references :country_method_version, foreign_key: { to_table: :agevidence_country_method_versions }
      t.string :name, null: false
      t.string :status, null: false, default: "proposed"
      t.text :objective, null: false
      t.json :launch_cell, null: false, default: {}
      t.json :canonical_workflow, null: false, default: []
      t.json :required_outputs, null: false, default: []
      t.text :intended_output
      t.timestamps
    end
    add_index :agevidence_country_pilots, [:country_program_id, :name], unique: true,
      name: "idx_country_pilots_program_name"

    create_table :agevidence_country_claim_policies do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.references :country_method_version, foreign_key: { to_table: :agevidence_country_method_versions }
      t.string :name, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "draft"
      t.json :claim_dimensions, null: false, default: []
      t.json :allocation_rules, null: false, default: {}
      t.text :authority_statement, null: false
      t.timestamps
    end
    add_index :agevidence_country_claim_policies, [:country_program_id, :name, :version], unique: true,
      name: "idx_country_claim_policies_identity"

    create_table :agevidence_country_registries do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.references :country_method_version, foreign_key: { to_table: :agevidence_country_method_versions }
      t.string :name, null: false
      t.string :authority, null: false
      t.string :identifier_scheme
      t.string :submission_format
      t.string :status, null: false, default: "research"
      t.timestamps
    end
    add_index :agevidence_country_registries, [:country_program_id, :name], unique: true,
      name: "idx_country_registries_program_name"

    create_table :agevidence_country_verification_profiles do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.references :country_method_version, foreign_key: { to_table: :agevidence_country_method_versions }
      t.string :name, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "draft"
      t.json :verifier_requirements, null: false, default: []
      t.json :materiality_rules, null: false, default: {}
      t.json :submission_checks, null: false, default: []
      t.timestamps
    end
    add_index :agevidence_country_verification_profiles, [:country_program_id, :name, :version], unique: true,
      name: "idx_country_verification_profiles_identity"

    create_table :agevidence_country_data_policies do |t|
      t.references :country_program, null: false, foreign_key: { to_table: :agevidence_country_programs }
      t.string :name, null: false
      t.string :version, null: false
      t.string :status, null: false, default: "draft"
      t.text :residency_requirement
      t.text :indigenous_or_community_rights
      t.text :language_requirement
      t.text :retention_policy
      t.json :selective_disclosure_rules, null: false, default: {}
      t.timestamps
    end
    add_index :agevidence_country_data_policies, [:country_program_id, :name, :version], unique: true,
      name: "idx_country_data_policies_identity"

    add_reference :agevidence_developer_projects, :country_program,
      foreign_key: { to_table: :agevidence_country_programs }
    add_column :agevidence_developer_projects, :country_context, :json, null: false, default: {}
    add_column :agevidence_developer_projects, :country_determination, :json, null: false, default: {}
    add_column :agevidence_developer_projects, :country_determination_status, :string

    add_reference :protocols, :country_method_version,
      foreign_key: { to_table: :agevidence_country_method_versions }

    add_reference :agevidence_model_runs, :country_adapter,
      foreign_key: { to_table: :agevidence_country_adapters }

    add_reference :agevidence_artifact_engagements, :country_program,
      foreign_key: { to_table: :agevidence_country_programs }

    add_reference :evidence_bundles, :country_claim_policy,
      foreign_key: { to_table: :agevidence_country_claim_policies }
    add_reference :evidence_bundles, :country_verification_profile,
      foreign_key: { to_table: :agevidence_country_verification_profiles }

    add_reference :agevidence_reliance_events, :country_institution,
      foreign_key: { to_table: :agevidence_country_institutions }
    add_reference :agevidence_reliance_events, :country_method_version,
      foreign_key: { to_table: :agevidence_country_method_versions }
  end
end
