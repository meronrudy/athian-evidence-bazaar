class CreateCampaignControlPlane < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_accounts do |t|
      t.string :external_id, null: false
      t.string :name, null: false
      t.string :domain
      t.string :country_code, null: false
      t.string :subsector
      t.string :funding_stage
      t.bigint :capital_raised_cents, null: false, default: 0
      t.string :status, null: false, default: "identified"
      t.string :qualification_level, null: false, default: "unqualified"
      t.integer :priority_score, null: false, default: 0
      t.string :authoritative_system
      t.string :evidence_obligation_code
      t.text :evidence_obligation_summary
      t.string :salesforce_account_id
      t.string :apollo_account_id
      t.references :developer_account, foreign_key: { to_table: :agevidence_developer_accounts }
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_accounts, :external_id, unique: true
    add_index :campaign_accounts, :domain, unique: true
    add_index :campaign_accounts, :salesforce_account_id, unique: true
    add_index :campaign_accounts, :apollo_account_id, unique: true
    add_index :campaign_accounts, %i[country_code status]
    add_index :campaign_accounts, %i[qualification_level priority_score]

    create_table :campaign_contact_refs do |t|
      t.references :campaign_account, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :display_name
      t.string :role_category
      t.string :email_domain
      t.string :salesforce_contact_id
      t.string :apollo_person_id
      t.boolean :technical_authority, null: false, default: false
      t.boolean :commercial_authority, null: false, default: false
      t.boolean :scientific_authority, null: false, default: false
      t.string :contactability_status, null: false, default: "unknown"
      t.datetime :last_enriched_at
      t.datetime :last_synced_at
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_contact_refs, %i[campaign_account_id external_id], unique: true, name: "idx_campaign_contact_refs_account_external"
    add_index :campaign_contact_refs, :salesforce_contact_id, unique: true
    add_index :campaign_contact_refs, :apollo_person_id, unique: true
    add_index :campaign_contact_refs, %i[campaign_account_id contactability_status], name: "idx_campaign_contact_refs_contactability"

    create_table :campaign_activation_paths do |t|
      t.references :campaign_account, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :path_type, null: false
      t.string :status, null: false, default: "invited"
      t.string :repository_sha
      t.string :guide_path
      t.string :sdk_version
      t.string :cli_version
      t.string :developer_project_external_id
      t.datetime :invited_at
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.string :failure_code
      t.integer :support_minutes, null: false, default: 0
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_activation_paths, :external_id, unique: true
    add_index :campaign_activation_paths, %i[campaign_account_id path_type status], name: "idx_campaign_activation_paths_account"
    add_index :campaign_activation_paths, :repository_sha

    create_table :campaign_touches do |t|
      t.references :campaign_account, null: false, foreign_key: true
      t.references :campaign_contact_ref, foreign_key: true
      t.string :touch_type, null: false
      t.string :source_system, null: false
      t.string :external_reference
      t.string :repository_sha
      t.string :content_reference
      t.datetime :occurred_at, null: false
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_touches, %i[campaign_account_id touch_type occurred_at], name: "idx_campaign_touches_account_type"
    add_index :campaign_touches, %i[source_system external_reference touch_type], name: "idx_campaign_touches_external"

    create_table :campaign_technical_qualifications do |t|
      t.references :campaign_account, null: false, foreign_key: true
      t.references :developer_project, foreign_key: { to_table: :agevidence_developer_projects }
      t.string :external_id, null: false
      t.string :status, null: false, default: "draft"
      t.string :qualification_level, null: false
      t.boolean :authoritative_system_confirmed, null: false, default: false
      t.integer :supported_event_count, null: false, default: 0
      t.integer :required_event_count, null: false, default: 0
      t.integer :evidence_gap_count, null: false, default: 0
      t.integer :unreviewed_candidate_count, null: false, default: 0
      t.string :country_code
      t.string :country_adapter_identifier
      t.string :named_obligation_code
      t.string :named_relying_party_type
      t.text :qualification_reason
      t.datetime :qualified_at
      t.string :country_adapter_readiness
      t.string :institution_profile
      t.string :obligation_profile
      t.integer :local_evidence_gap_count, null: false, default: 0
      t.string :cross_country_portability_result
      t.json :snapshot_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_technical_qualifications, :external_id, unique: true, name: "idx_campaign_tq_external"
    add_index :campaign_technical_qualifications, %i[campaign_account_id qualification_level], name: "idx_campaign_tq_account_level"
    add_index :campaign_technical_qualifications, :created_at

    create_table :campaign_commercial_handoffs do |t|
      t.references :campaign_account, null: false, foreign_key: true
      t.references :campaign_technical_qualification, null: false, foreign_key: true, index: { name: "idx_campaign_handoffs_qualification" }
      t.string :external_id, null: false
      t.string :product_code, null: false
      t.string :status, null: false, default: "ready"
      t.string :scope_digest, null: false
      t.bigint :planning_value_cents, null: false, default: 0
      t.bigint :contracted_value_cents, null: false, default: 0
      t.bigint :cash_collected_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.string :salesforce_opportunity_id
      t.datetime :sent_at
      t.datetime :accepted_at
      t.datetime :contracted_at
      t.datetime :cash_recorded_at
      t.json :scope_json, null: false, default: {}
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_commercial_handoffs, :external_id, unique: true
    add_index :campaign_commercial_handoffs, :salesforce_opportunity_id, unique: true
    add_index :campaign_commercial_handoffs, %i[campaign_account_id status], name: "idx_campaign_handoffs_account_status"
    add_index :campaign_commercial_handoffs,
              %i[campaign_account_id campaign_technical_qualification_id product_code scope_digest],
              unique: true,
              name: "idx_campaign_handoffs_idempotency"

    create_table :campaign_connector_outboxes do |t|
      t.string :destination, null: false
      t.string :event_type, null: false
      t.string :aggregate_type, null: false
      t.bigint :aggregate_id
      t.json :payload_json, null: false, default: {}
      t.string :idempotency_key, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempt_count, null: false, default: 0
      t.datetime :next_attempt_at
      t.text :last_error
      t.datetime :delivered_at
      t.timestamps
    end
    add_index :campaign_connector_outboxes, :idempotency_key, unique: true
    add_index :campaign_connector_outboxes, %i[destination status], name: "idx_campaign_connector_outboxes_destination"
    add_index :campaign_connector_outboxes, :next_attempt_at
    add_index :campaign_connector_outboxes, %i[aggregate_type aggregate_id], name: "idx_campaign_connector_outboxes_aggregate"

    create_table :campaign_capability_attributions do |t|
      t.references :campaign_account, null: false, foreign_key: true
      t.references :campaign_commercial_handoff, foreign_key: true, index: { name: "idx_campaign_capabilities_handoff" }
      t.string :capability_type, null: false
      t.string :capability_identifier, null: false
      t.string :repository_sha, null: false
      t.string :source_event_type
      t.string :country_adapter_identifier
      t.string :artifact_product_code
      t.bigint :contracted_value_cents, null: false, default: 0
      t.bigint :cash_collected_cents, null: false, default: 0
      t.integer :support_minutes, null: false, default: 0
      t.integer :reuse_count, null: false, default: 0
      t.json :metadata_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_capability_attributions, %i[capability_type capability_identifier repository_sha], name: "idx_campaign_capabilities_identity"
    add_index :campaign_capability_attributions, %i[campaign_account_id capability_type], name: "idx_campaign_capabilities_account"

    create_table :campaign_country_programs do |t|
      t.string :country_code, null: false
      t.string :region_code
      t.string :status, null: false, default: "research_not_started"
      t.string :research_status, null: false, default: "research_not_started"
      t.string :adapter_status, null: false, default: "research_not_started"
      t.string :publication_status, null: false, default: "research_not_started"
      t.string :developer_guide_status, null: false, default: "research_not_started"
      t.string :commercial_readiness, null: false, default: "research_not_started"
      t.string :canonical_adapter_identifier
      t.json :limitations_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_country_programs, :country_code, unique: true
    add_index :campaign_country_programs, :status

    create_table :campaign_institution_profiles do |t|
      t.references :campaign_country_program, null: false, foreign_key: true, index: { name: "idx_campaign_institutions_country" }
      t.string :external_id, null: false
      t.string :name, null: false
      t.string :institution_type, null: false
      t.string :status, null: false, default: "research_not_started"
      t.json :requirements_json, null: false, default: {}
      t.json :limitations_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_institution_profiles, :external_id, unique: true

    create_table :campaign_obligation_profiles do |t|
      t.references :campaign_country_program, null: false, foreign_key: true, index: { name: "idx_campaign_obligations_country" }
      t.string :external_id, null: false
      t.string :obligation_code, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "research_not_started"
      t.json :required_evidence_json, null: false, default: {}
      t.json :limitations_json, null: false, default: {}
      t.timestamps
    end
    add_index :campaign_obligation_profiles, :external_id, unique: true
    add_index :campaign_obligation_profiles, :obligation_code

    create_table :campaign_adapter_readiness_assessments do |t|
      t.references :campaign_country_program, null: false, foreign_key: true, index: { name: "idx_campaign_readiness_country" }
      t.string :external_id, null: false
      t.string :adapter_identifier, null: false
      t.string :status, null: false, default: "research_not_started"
      t.boolean :research_only, null: false, default: true
      t.boolean :external_review_required, null: false, default: true
      t.json :unsupported_rules_json, null: false, default: {}
      t.json :limitations_json, null: false, default: {}
      t.datetime :assessed_at
      t.timestamps
    end
    add_index :campaign_adapter_readiness_assessments, :external_id, unique: true
    add_index :campaign_adapter_readiness_assessments, %i[adapter_identifier status], name: "idx_campaign_readiness_adapter"
  end
end
