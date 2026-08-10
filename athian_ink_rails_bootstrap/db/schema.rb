# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_08_10_000100) do
  create_table "agevidence_artifact_engagements", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "developer_project_id", null: false
    t.integer "evidence_bundle_id"
    t.string "product_code", null: false
    t.string "pipeline_stage", default: "identified", null: false
    t.string "billing_type", default: "fixed_fee", null: false
    t.integer "list_price_cents", limit: 8, default: 0, null: false
    t.integer "quoted_price_cents", limit: 8, default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "commercial_status", default: "illustrative", null: false
    t.date "started_on"
    t.date "completed_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["developer_project_id"], name: "index_agevidence_artifact_engagements_on_developer_project_id"
    t.index ["evidence_bundle_id"], name: "index_agevidence_artifact_engagements_on_evidence_bundle_id"
    t.index ["organization_id"], name: "index_agevidence_artifact_engagements_on_organization_id"
  end

  create_table "agevidence_artifact_orders", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "developer_project_id", null: false
    t.integer "pricing_quote_id", null: false
    t.integer "artifact_engagement_id"
    t.integer "evidence_bundle_id"
    t.string "external_id", null: false
    t.string "product_code", null: false
    t.string "status", default: "quoted", null: false
    t.integer "amount_cents", limit: 8, default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "checkout_url"
    t.datetime "checkout_completed_at"
    t.datetime "assembled_at"
    t.datetime "canceled_at"
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_engagement_id"], name: "index_agevidence_artifact_orders_on_artifact_engagement_id"
    t.index ["developer_project_id", "status"], name: "idx_agev_artifact_orders_project"
    t.index ["developer_project_id"], name: "index_agevidence_artifact_orders_on_developer_project_id"
    t.index ["evidence_bundle_id"], name: "index_agevidence_artifact_orders_on_evidence_bundle_id"
    t.index ["external_id"], name: "index_agevidence_artifact_orders_on_external_id", unique: true
    t.index ["organization_id"], name: "index_agevidence_artifact_orders_on_organization_id"
    t.index ["pricing_quote_id"], name: "index_agevidence_artifact_orders_on_pricing_quote_id"
  end

  create_table "agevidence_country_adapters", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.integer "country_method_version_id", null: false
    t.integer "country_claim_policy_id"
    t.integer "country_verification_profile_id"
    t.integer "country_data_policy_id"
    t.integer "commitment_receipt_id"
    t.string "adapter_id", null: false
    t.string "version", null: false
    t.string "status", default: "scaffold", null: false
    t.string "country_code", null: false
    t.json "manifest", default: {}, null: false
    t.datetime "activated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adapter_id", "version"], name: "idx_agev_country_adapters", unique: true
    t.index ["commitment_receipt_id"], name: "index_agevidence_country_adapters_on_commitment_receipt_id"
    t.index ["country_claim_policy_id"], name: "index_agevidence_country_adapters_on_country_claim_policy_id"
    t.index ["country_data_policy_id"], name: "index_agevidence_country_adapters_on_country_data_policy_id"
    t.index ["country_method_version_id"], name: "index_agevidence_country_adapters_on_country_method_version_id"
    t.index ["country_program_id"], name: "index_agevidence_country_adapters_on_country_program_id"
    t.index ["country_verification_profile_id"], name: "idx_on_country_verification_profile_id_6b38e74923"
  end

  create_table "agevidence_country_claim_policies", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.string "policy_id", null: false
    t.string "version", null: false
    t.string "status", default: "active", null: false
    t.json "policy_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_program_id", "policy_id", "version"], name: "idx_agev_claim_policies", unique: true
    t.index ["country_program_id"], name: "index_agevidence_country_claim_policies_on_country_program_id"
  end

  create_table "agevidence_country_data_policies", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.string "policy_id", null: false
    t.string "version", null: false
    t.string "status", default: "active", null: false
    t.json "policy_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_program_id", "policy_id", "version"], name: "idx_agev_data_policies", unique: true
    t.index ["country_program_id"], name: "index_agevidence_country_data_policies_on_country_program_id"
  end

  create_table "agevidence_country_determinations", force: :cascade do |t|
    t.integer "developer_project_id", null: false
    t.integer "country_program_id", null: false
    t.integer "country_adapter_id", null: false
    t.integer "country_method_version_id", null: false
    t.integer "supersedes_id"
    t.integer "receipt_id"
    t.string "status", null: false
    t.json "normalized_result", default: {}, null: false
    t.string "result_digest"
    t.datetime "evaluated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_adapter_id"], name: "index_agevidence_country_determinations_on_country_adapter_id"
    t.index ["country_method_version_id"], name: "idx_on_country_method_version_id_986a983240"
    t.index ["country_program_id"], name: "index_agevidence_country_determinations_on_country_program_id"
    t.index ["developer_project_id", "country_adapter_id", "evaluated_at"], name: "idx_agev_country_determinations"
    t.index ["developer_project_id"], name: "idx_on_developer_project_id_6e5e8b2cf1"
    t.index ["receipt_id"], name: "index_agevidence_country_determinations_on_receipt_id"
    t.index ["supersedes_id"], name: "index_agevidence_country_determinations_on_supersedes_id"
  end

  create_table "agevidence_country_institutions", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.string "name", null: false
    t.string "institution_role", null: false
    t.string "status", default: "scaffold", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_program_id"], name: "index_agevidence_country_institutions_on_country_program_id"
  end

  create_table "agevidence_country_method_versions", force: :cascade do |t|
    t.integer "country_method_id", null: false
    t.string "version", null: false
    t.string "authority_version"
    t.string "status", default: "active", null: false
    t.date "effective_on"
    t.date "retired_on"
    t.json "method_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_method_id", "version"], name: "idx_agev_method_versions", unique: true
    t.index ["country_method_id"], name: "index_agevidence_country_method_versions_on_country_method_id"
  end

  create_table "agevidence_country_methods", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.string "method_id", null: false
    t.string "name", null: false
    t.string "authority_name"
    t.string "status", default: "scaffold", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_program_id", "method_id"], name: "idx_agev_country_methods", unique: true
    t.index ["country_program_id"], name: "index_agevidence_country_methods_on_country_program_id"
  end

  create_table "agevidence_country_pilots", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.string "name", null: false
    t.string "status", default: "scaffold", null: false
    t.date "started_on"
    t.date "ended_on"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_program_id"], name: "index_agevidence_country_pilots_on_country_program_id"
  end

  create_table "agevidence_country_programs", force: :cascade do |t|
    t.string "name", null: false
    t.string "country_code", null: false
    t.string "program_type"
    t.string "authority_name"
    t.string "status", default: "scaffold", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "name"], name: "index_agevidence_country_programs_on_country_code_and_name", unique: true
  end

  create_table "agevidence_country_registries", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.string "name", null: false
    t.string "registry_code"
    t.string "status", default: "scaffold", null: false
    t.json "mapping_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_program_id"], name: "index_agevidence_country_registries_on_country_program_id"
  end

  create_table "agevidence_country_verification_profiles", force: :cascade do |t|
    t.integer "country_program_id", null: false
    t.string "profile_id", null: false
    t.string "version", null: false
    t.string "status", default: "active", null: false
    t.json "profile_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_program_id", "profile_id", "version"], name: "idx_agev_verification_profiles", unique: true
    t.index ["country_program_id"], name: "idx_on_country_program_id_89f264c8e5"
  end

  create_table "agevidence_developer_accounts", force: :cascade do |t|
    t.integer "organization_id"
    t.string "name", null: false
    t.string "website"
    t.string "funding_stage"
    t.integer "capital_raised_cents", limit: 8, default: 0, null: false
    t.string "primary_segment"
    t.string "headquarters"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_agevidence_developer_accounts_on_name", unique: true
    t.index ["organization_id"], name: "index_agevidence_developer_accounts_on_organization_id"
  end

  create_table "agevidence_developer_projects", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "developer_account_id", null: false
    t.integer "protocol_id"
    t.integer "avsa_id"
    t.string "name", null: false
    t.string "project_type", null: false
    t.string "commercialization_stage"
    t.text "target_claim"
    t.string "protocol_status", default: "mapping", null: false
    t.string "integration_status", default: "not_started", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "country_program_id"
    t.bigint "primary_country_program_id"
    t.json "country_context", default: {}, null: false
    t.index ["avsa_id"], name: "index_agevidence_developer_projects_on_avsa_id"
    t.index ["country_program_id"], name: "index_agevidence_developer_projects_on_country_program_id"
    t.index ["developer_account_id"], name: "index_agevidence_developer_projects_on_developer_account_id"
    t.index ["organization_id"], name: "index_agevidence_developer_projects_on_organization_id"
    t.index ["protocol_id"], name: "index_agevidence_developer_projects_on_protocol_id"
  end

  create_table "agevidence_evidence_candidates", force: :cascade do |t|
    t.integer "model_run_id", null: false
    t.integer "evidence_item_id"
    t.integer "receipt_id"
    t.string "candidate_type", null: false
    t.text "claim_text", null: false
    t.json "source_references", default: [], null: false
    t.decimal "model_confidence", precision: 5, scale: 4
    t.string "review_status", default: "review_required", null: false
    t.text "review_notes"
    t.string "reviewed_by"
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evidence_item_id"], name: "index_agevidence_evidence_candidates_on_evidence_item_id"
    t.index ["model_run_id"], name: "index_agevidence_evidence_candidates_on_model_run_id"
    t.index ["receipt_id"], name: "index_agevidence_evidence_candidates_on_receipt_id"
  end

  create_table "agevidence_evidence_gaps", force: :cascade do |t|
    t.integer "model_run_id", null: false
    t.string "gap_type", null: false
    t.string "requirement", null: false
    t.text "description", null: false
    t.string "severity", null: false
    t.json "source_context", default: {}, null: false
    t.string "resolution_status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_run_id"], name: "index_agevidence_evidence_gaps_on_model_run_id"
  end

  create_table "agevidence_model_adapters", force: :cascade do |t|
    t.string "adapter_id", null: false
    t.string "base_model_id", null: false
    t.string "provider"
    t.string "license"
    t.string "runtime"
    t.string "weights_digest"
    t.string "adapter_digest"
    t.integer "context_limit"
    t.boolean "multimodal", default: false, null: false
    t.string "status", default: "reference", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adapter_id"], name: "index_agevidence_model_adapters_on_adapter_id", unique: true
  end

  create_table "agevidence_model_runs", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "developer_project_id", null: false
    t.integer "model_adapter_id", null: false
    t.integer "receipt_id"
    t.string "task", null: false
    t.string "status", default: "queued", null: false
    t.string "prompt_digest"
    t.string "retrieval_digest"
    t.json "input_manifest", default: {}, null: false
    t.json "normalized_output", default: {}, null: false
    t.string "output_digest"
    t.json "runtime_metadata", default: {}, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "country_adapter_id"
    t.index ["country_adapter_id"], name: "index_agevidence_model_runs_on_country_adapter_id"
    t.index ["developer_project_id"], name: "index_agevidence_model_runs_on_developer_project_id"
    t.index ["model_adapter_id"], name: "index_agevidence_model_runs_on_model_adapter_id"
    t.index ["organization_id"], name: "index_agevidence_model_runs_on_organization_id"
    t.index ["receipt_id"], name: "index_agevidence_model_runs_on_receipt_id"
  end

  create_table "agevidence_pricing_quotes", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "developer_project_id", null: false
    t.string "external_id", null: false
    t.string "product_code", null: false
    t.string "pricing_version", null: false
    t.string "currency", default: "USD", null: false
    t.integer "amount_cents", limit: 8, default: 0, null: false
    t.json "input_json", default: {}, null: false
    t.json "breakdown_json", default: [], null: false
    t.string "status", default: "quoted", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["developer_project_id", "product_code", "status"], name: "idx_agev_pricing_quotes_project"
    t.index ["developer_project_id"], name: "index_agevidence_pricing_quotes_on_developer_project_id"
    t.index ["external_id"], name: "index_agevidence_pricing_quotes_on_external_id", unique: true
    t.index ["organization_id"], name: "index_agevidence_pricing_quotes_on_organization_id"
  end

  create_table "agevidence_reliance_events", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "artifact_engagement_id", null: false
    t.integer "evidence_bundle_id", null: false
    t.string "relying_party_name", null: false
    t.string "relying_party_role", null: false
    t.string "decision_type", null: false
    t.string "outcome", null: false
    t.string "evidence_bundle_digest"
    t.datetime "occurred_at", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_engagement_id"], name: "index_agevidence_reliance_events_on_artifact_engagement_id"
    t.index ["evidence_bundle_id"], name: "index_agevidence_reliance_events_on_evidence_bundle_id"
    t.index ["organization_id"], name: "index_agevidence_reliance_events_on_organization_id"
  end

  create_table "agevidence_review_decisions", force: :cascade do |t|
    t.integer "evidence_candidate_id", null: false
    t.integer "receipt_id"
    t.string "reviewer_role", null: false
    t.string "decision", null: false
    t.text "reason", null: false
    t.string "policy_version", null: false
    t.datetime "decided_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evidence_candidate_id"], name: "index_agevidence_review_decisions_on_evidence_candidate_id"
    t.index ["receipt_id"], name: "index_agevidence_review_decisions_on_receipt_id"
  end

  create_table "agevidence_source_records", force: :cascade do |t|
    t.integer "organization_id"
    t.integer "developer_project_id", null: false
    t.integer "source_event_id"
    t.integer "evidence_projection_id"
    t.integer "receipt_id"
    t.string "document_id", null: false
    t.string "evidence_type", null: false
    t.string "evidence_class", default: "source_record", null: false
    t.string "source_system"
    t.string "controlled_uri", null: false
    t.string "commitment", null: false
    t.string "disclosure_status", default: "restricted", null: false
    t.string "status", default: "referenced", null: false
    t.datetime "captured_at"
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["developer_project_id", "document_id"], name: "idx_agev_source_records_project_document", unique: true
    t.index ["developer_project_id"], name: "index_agevidence_source_records_on_developer_project_id"
    t.index ["evidence_projection_id"], name: "index_agevidence_source_records_on_evidence_projection_id"
    t.index ["organization_id"], name: "index_agevidence_source_records_on_organization_id"
    t.index ["receipt_id"], name: "index_agevidence_source_records_on_receipt_id"
    t.index ["source_event_id"], name: "index_agevidence_source_records_on_source_event_id"
    t.index ["status"], name: "index_agevidence_source_records_on_status"
  end

  create_table "api_keys", force: :cascade do |t|
    t.integer "user_id"
    t.bigint "project_id"
    t.string "name", null: false
    t.string "key", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_api_keys_on_key", unique: true
    t.index ["project_id"], name: "index_api_keys_on_project_id"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "api_logs", force: :cascade do |t|
    t.integer "api_key_id"
    t.string "endpoint", null: false
    t.string "method", null: false
    t.integer "status", null: false
    t.string "request_id", null: false
    t.decimal "duration", precision: 10, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_id"], name: "index_api_logs_on_api_key_id"
    t.index ["endpoint"], name: "index_api_logs_on_endpoint"
    t.index ["request_id"], name: "index_api_logs_on_request_id"
    t.index ["status"], name: "index_api_logs_on_status"
  end

  create_table "avsas", force: :cascade do |t|
    t.integer "protocol_id", null: false
    t.string "external_id", null: false
    t.string "title", null: false
    t.string "producer_name", null: false
    t.string "intervention_provider"
    t.string "vvb_name"
    t.string "buyer_name"
    t.string "status", default: "in_progress", null: false
    t.decimal "verified_quantity", precision: 14, scale: 3, default: "0.0", null: false
    t.string "unit", default: "tCO2e", null: false
    t.date "started_on"
    t.string "reporting_period"
    t.string "root_digest"
    t.string "local_verification_status", default: "indeterminate", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "methodology_name"
    t.string "methodology_version"
    t.index ["external_id"], name: "index_avsas_on_external_id", unique: true
    t.index ["protocol_id"], name: "index_avsas_on_protocol_id"
  end

  create_table "campaign_accounts", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "name", null: false
    t.string "domain"
    t.string "country_code", null: false
    t.string "subsector"
    t.string "funding_stage"
    t.bigint "capital_raised_cents", default: 0, null: false
    t.string "status", default: "identified", null: false
    t.string "qualification_level", default: "unqualified", null: false
    t.integer "priority_score", default: 0, null: false
    t.string "authoritative_system"
    t.string "evidence_obligation_code"
    t.text "evidence_obligation_summary"
    t.string "salesforce_account_id"
    t.string "apollo_account_id"
    t.integer "developer_account_id"
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["apollo_account_id"], name: "index_campaign_accounts_on_apollo_account_id", unique: true
    t.index ["country_code", "status"], name: "index_campaign_accounts_on_country_code_and_status"
    t.index ["developer_account_id"], name: "index_campaign_accounts_on_developer_account_id"
    t.index ["domain"], name: "index_campaign_accounts_on_domain", unique: true
    t.index ["external_id"], name: "index_campaign_accounts_on_external_id", unique: true
    t.index ["qualification_level", "priority_score"], name: "idx_on_qualification_level_priority_score_ddbf0eb5d8"
    t.index ["salesforce_account_id"], name: "index_campaign_accounts_on_salesforce_account_id", unique: true
  end

  create_table "campaign_activation_paths", force: :cascade do |t|
    t.integer "campaign_account_id", null: false
    t.string "external_id", null: false
    t.string "path_type", null: false
    t.string "status", default: "invited", null: false
    t.string "repository_sha"
    t.string "guide_path"
    t.string "sdk_version"
    t.string "cli_version"
    t.string "developer_project_external_id"
    t.datetime "invited_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.string "failure_code"
    t.integer "support_minutes", default: 0, null: false
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_account_id", "path_type", "status"], name: "idx_campaign_activation_paths_account"
    t.index ["campaign_account_id"], name: "index_campaign_activation_paths_on_campaign_account_id"
    t.index ["external_id"], name: "index_campaign_activation_paths_on_external_id", unique: true
    t.index ["repository_sha"], name: "index_campaign_activation_paths_on_repository_sha"
  end

  create_table "campaign_adapter_readiness_assessments", force: :cascade do |t|
    t.integer "campaign_country_program_id", null: false
    t.string "external_id", null: false
    t.string "adapter_identifier", null: false
    t.string "status", default: "research_not_started", null: false
    t.boolean "research_only", default: true, null: false
    t.boolean "external_review_required", default: true, null: false
    t.json "unsupported_rules_json", default: {}, null: false
    t.json "limitations_json", default: {}, null: false
    t.datetime "assessed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adapter_identifier", "status"], name: "idx_campaign_readiness_adapter"
    t.index ["campaign_country_program_id"], name: "idx_campaign_readiness_country"
    t.index ["external_id"], name: "index_campaign_adapter_readiness_assessments_on_external_id", unique: true
  end

  create_table "campaign_capability_attributions", force: :cascade do |t|
    t.integer "campaign_account_id", null: false
    t.integer "campaign_commercial_handoff_id"
    t.string "capability_type", null: false
    t.string "capability_identifier", null: false
    t.string "repository_sha", null: false
    t.string "source_event_type"
    t.string "country_adapter_identifier"
    t.string "artifact_product_code"
    t.bigint "contracted_value_cents", default: 0, null: false
    t.bigint "cash_collected_cents", default: 0, null: false
    t.integer "support_minutes", default: 0, null: false
    t.integer "reuse_count", default: 0, null: false
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_account_id", "capability_type"], name: "idx_campaign_capabilities_account"
    t.index ["campaign_account_id"], name: "index_campaign_capability_attributions_on_campaign_account_id"
    t.index ["campaign_commercial_handoff_id"], name: "idx_campaign_capabilities_handoff"
    t.index ["capability_type", "capability_identifier", "repository_sha"], name: "idx_campaign_capabilities_identity"
  end

  create_table "campaign_commercial_handoffs", force: :cascade do |t|
    t.integer "campaign_account_id", null: false
    t.integer "campaign_technical_qualification_id", null: false
    t.string "external_id", null: false
    t.string "product_code", null: false
    t.string "status", default: "ready", null: false
    t.string "scope_digest", null: false
    t.bigint "planning_value_cents", default: 0, null: false
    t.bigint "contracted_value_cents", default: 0, null: false
    t.bigint "cash_collected_cents", default: 0, null: false
    t.string "currency", default: "USD", null: false
    t.string "salesforce_opportunity_id"
    t.datetime "sent_at"
    t.datetime "accepted_at"
    t.datetime "contracted_at"
    t.datetime "cash_recorded_at"
    t.json "scope_json", default: {}, null: false
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "salesforce_proposal_id"
    t.string "proposal_reference"
    t.string "proposal_terms_digest"
    t.string "contract_reference"
    t.string "contract_terms_digest"
    t.string "invoice_reference"
    t.string "cash_collection_reference"
    t.string "revenue_system"
    t.datetime "last_revenue_signal_at"
    t.index ["campaign_account_id", "campaign_technical_qualification_id", "product_code", "scope_digest"], name: "idx_campaign_handoffs_idempotency", unique: true
    t.index ["campaign_account_id", "status"], name: "idx_campaign_handoffs_account_status"
    t.index ["campaign_account_id"], name: "index_campaign_commercial_handoffs_on_campaign_account_id"
    t.index ["campaign_technical_qualification_id"], name: "idx_campaign_handoffs_qualification"
    t.index ["cash_collection_reference"], name: "idx_on_cash_collection_reference_2505a0b12d", unique: true
    t.index ["contract_reference"], name: "index_campaign_commercial_handoffs_on_contract_reference", unique: true
    t.index ["external_id"], name: "index_campaign_commercial_handoffs_on_external_id", unique: true
    t.index ["invoice_reference"], name: "index_campaign_commercial_handoffs_on_invoice_reference", unique: true
    t.index ["last_revenue_signal_at"], name: "index_campaign_commercial_handoffs_on_last_revenue_signal_at"
    t.index ["salesforce_opportunity_id"], name: "idx_on_salesforce_opportunity_id_704b6d20e9", unique: true
    t.index ["salesforce_proposal_id"], name: "index_campaign_commercial_handoffs_on_salesforce_proposal_id", unique: true
  end

  create_table "campaign_connector_outboxes", force: :cascade do |t|
    t.string "destination", null: false
    t.string "event_type", null: false
    t.string "aggregate_type", null: false
    t.bigint "aggregate_id"
    t.json "payload_json", default: {}, null: false
    t.string "idempotency_key", null: false
    t.string "status", default: "pending", null: false
    t.integer "attempt_count", default: 0, null: false
    t.datetime "next_attempt_at"
    t.text "last_error"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregate_type", "aggregate_id"], name: "idx_campaign_connector_outboxes_aggregate"
    t.index ["destination", "status"], name: "idx_campaign_connector_outboxes_destination"
    t.index ["idempotency_key"], name: "index_campaign_connector_outboxes_on_idempotency_key", unique: true
    t.index ["next_attempt_at"], name: "index_campaign_connector_outboxes_on_next_attempt_at"
  end

  create_table "campaign_contact_refs", force: :cascade do |t|
    t.integer "campaign_account_id", null: false
    t.string "external_id", null: false
    t.string "display_name"
    t.string "role_category"
    t.string "email_domain"
    t.string "salesforce_contact_id"
    t.string "apollo_person_id"
    t.boolean "technical_authority", default: false, null: false
    t.boolean "commercial_authority", default: false, null: false
    t.boolean "scientific_authority", default: false, null: false
    t.string "contactability_status", default: "unknown", null: false
    t.datetime "last_enriched_at"
    t.datetime "last_synced_at"
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["apollo_person_id"], name: "index_campaign_contact_refs_on_apollo_person_id", unique: true
    t.index ["campaign_account_id", "contactability_status"], name: "idx_campaign_contact_refs_contactability"
    t.index ["campaign_account_id", "external_id"], name: "idx_campaign_contact_refs_account_external", unique: true
    t.index ["campaign_account_id"], name: "index_campaign_contact_refs_on_campaign_account_id"
    t.index ["salesforce_contact_id"], name: "index_campaign_contact_refs_on_salesforce_contact_id", unique: true
  end

  create_table "campaign_country_programs", force: :cascade do |t|
    t.string "country_code", null: false
    t.string "region_code"
    t.string "status", default: "research_not_started", null: false
    t.string "research_status", default: "research_not_started", null: false
    t.string "adapter_status", default: "research_not_started", null: false
    t.string "publication_status", default: "research_not_started", null: false
    t.string "developer_guide_status", default: "research_not_started", null: false
    t.string "commercial_readiness", default: "research_not_started", null: false
    t.string "canonical_adapter_identifier"
    t.json "limitations_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_campaign_country_programs_on_country_code", unique: true
    t.index ["status"], name: "index_campaign_country_programs_on_status"
  end

  create_table "campaign_institution_profiles", force: :cascade do |t|
    t.integer "campaign_country_program_id", null: false
    t.string "external_id", null: false
    t.string "name", null: false
    t.string "institution_type", null: false
    t.string "status", default: "research_not_started", null: false
    t.json "requirements_json", default: {}, null: false
    t.json "limitations_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_country_program_id"], name: "idx_campaign_institutions_country"
    t.index ["external_id"], name: "index_campaign_institution_profiles_on_external_id", unique: true
  end

  create_table "campaign_obligation_profiles", force: :cascade do |t|
    t.integer "campaign_country_program_id", null: false
    t.string "external_id", null: false
    t.string "obligation_code", null: false
    t.string "name", null: false
    t.string "status", default: "research_not_started", null: false
    t.json "required_evidence_json", default: {}, null: false
    t.json "limitations_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_country_program_id"], name: "idx_campaign_obligations_country"
    t.index ["external_id"], name: "index_campaign_obligation_profiles_on_external_id", unique: true
    t.index ["obligation_code"], name: "index_campaign_obligation_profiles_on_obligation_code"
  end

  create_table "campaign_technical_qualifications", force: :cascade do |t|
    t.integer "campaign_account_id", null: false
    t.integer "developer_project_id"
    t.string "external_id", null: false
    t.string "status", default: "draft", null: false
    t.string "qualification_level", null: false
    t.boolean "authoritative_system_confirmed", default: false, null: false
    t.integer "supported_event_count", default: 0, null: false
    t.integer "required_event_count", default: 0, null: false
    t.integer "evidence_gap_count", default: 0, null: false
    t.integer "unreviewed_candidate_count", default: 0, null: false
    t.string "country_code"
    t.string "country_adapter_identifier"
    t.string "named_obligation_code"
    t.string "named_relying_party_type"
    t.text "qualification_reason"
    t.datetime "qualified_at"
    t.string "country_adapter_readiness"
    t.string "institution_profile"
    t.string "obligation_profile"
    t.integer "local_evidence_gap_count", default: 0, null: false
    t.string "cross_country_portability_result"
    t.json "snapshot_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_account_id", "qualification_level"], name: "idx_campaign_tq_account_level"
    t.index ["campaign_account_id"], name: "index_campaign_technical_qualifications_on_campaign_account_id"
    t.index ["created_at"], name: "index_campaign_technical_qualifications_on_created_at"
    t.index ["developer_project_id"], name: "idx_on_developer_project_id_bd229087ac"
    t.index ["external_id"], name: "idx_campaign_tq_external", unique: true
  end

  create_table "campaign_touches", force: :cascade do |t|
    t.integer "campaign_account_id", null: false
    t.integer "campaign_contact_ref_id"
    t.string "touch_type", null: false
    t.string "source_system", null: false
    t.string "external_reference"
    t.string "repository_sha"
    t.string "content_reference"
    t.datetime "occurred_at", null: false
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_account_id", "touch_type", "occurred_at"], name: "idx_campaign_touches_account_type"
    t.index ["campaign_account_id"], name: "index_campaign_touches_on_campaign_account_id"
    t.index ["campaign_contact_ref_id"], name: "index_campaign_touches_on_campaign_contact_ref_id"
    t.index ["source_system", "external_reference", "touch_type"], name: "idx_campaign_touches_external"
  end

  create_table "claim_groups", force: :cascade do |t|
    t.integer "avsa_id", null: false
    t.string "name", null: false
    t.decimal "verified_total", precision: 14, scale: 3, null: false
    t.string "unit", default: "tCO2e", null: false
    t.decimal "aggregate_cap_percent", precision: 5, scale: 2, default: "100.0", null: false
    t.string "finalization_status", default: "draft", null: false
    t.string "prior_claim_check_status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "retirement_status", default: "valid", null: false
    t.string "exclusivity_status", default: "valid", null: false
    t.index ["avsa_id"], name: "index_claim_groups_on_avsa_id"
  end

  create_table "claim_shares", force: :cascade do |t|
    t.integer "claim_group_id", null: false
    t.string "claimant_name", null: false
    t.string "claimant_role", null: false
    t.decimal "share_percent", precision: 5, scale: 2, null: false
    t.decimal "contribution_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "inventory_category"
    t.string "contract_right_digest"
    t.string "status", default: "proposed", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_group_id"], name: "index_claim_shares_on_claim_group_id"
  end

  create_table "commercial_order_events", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "from_state", null: false
    t.string "to_state", null: false
    t.string "event_type", null: false
    t.string "actor_type"
    t.integer "actor_id"
    t.text "reason"
    t.json "metadata_json", default: {}
    t.datetime "occurred_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_commercial_order_events_on_event_type"
    t.index ["order_id", "occurred_at"], name: "index_commercial_order_events_on_order_id_and_occurred_at"
    t.index ["order_id"], name: "index_commercial_order_events_on_order_id"
  end

  create_table "country_programs", force: :cascade do |t|
    t.string "name", null: false
    t.string "country_code", null: false
    t.text "description"
    t.string "status", default: "active", null: false
    t.integer "adapter_count", default: 0
    t.integer "profile_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_country_programs_on_country_code"
    t.index ["status"], name: "index_country_programs_on_status"
  end

  create_table "evidence_bundles", force: :cascade do |t|
    t.integer "avsa_id", null: false
    t.string "bundle_type", null: false
    t.string "name", null: false
    t.string "audience"
    t.string "status", default: "generated", null: false
    t.string "artifact_filename", null: false
    t.string "artifact_path"
    t.string "verification_status", default: "indeterminate", null: false
    t.text "problem"
    t.json "manifest", default: {}, null: false
    t.datetime "generated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "commercial_product_code"
    t.string "artifact_version"
    t.string "reliance_status", default: "not_relied_on", null: false
    t.integer "relying_party_count", default: 0, null: false
    t.integer "list_price_cents", limit: 8, default: 0, null: false
    t.integer "quoted_price_cents", limit: 8, default: 0, null: false
    t.bigint "acceptance_receipt_id"
    t.datetime "accepted_at"
    t.integer "country_adapter_id"
    t.integer "country_claim_policy_id"
    t.integer "country_verification_profile_id"
    t.integer "country_data_policy_id"
    t.integer "country_determination_id"
    t.index ["avsa_id", "bundle_type", "generated_at"], name: "idx_evidence_bundles_lookup"
    t.index ["avsa_id"], name: "index_evidence_bundles_on_avsa_id"
    t.index ["country_adapter_id"], name: "index_evidence_bundles_on_country_adapter_id"
    t.index ["country_claim_policy_id"], name: "index_evidence_bundles_on_country_claim_policy_id"
    t.index ["country_data_policy_id"], name: "index_evidence_bundles_on_country_data_policy_id"
    t.index ["country_determination_id"], name: "index_evidence_bundles_on_country_determination_id"
    t.index ["country_verification_profile_id"], name: "index_evidence_bundles_on_country_verification_profile_id"
  end

  create_table "evidence_items", force: :cascade do |t|
    t.integer "receipt_id", null: false
    t.string "name", null: false
    t.string "evidence_type", null: false
    t.string "source_system"
    t.string "commitment", null: false
    t.string "disclosure_status", default: "restricted", null: false
    t.boolean "required", default: true, null: false
    t.string "status", default: "present", null: false
    t.datetime "captured_at"
    t.json "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receipt_id"], name: "index_evidence_items_on_receipt_id"
  end

  create_table "evidence_projections", force: :cascade do |t|
    t.string "projection_type", null: false
    t.string "external_project_id"
    t.string "external_subject_type"
    t.string "external_subject_id"
    t.string "current_state", default: "indeterminate", null: false
    t.integer "source_event_id", null: false
    t.string "source_event_digest", null: false
    t.integer "projection_version", default: 1, null: false
    t.json "data_json", default: {}, null: false
    t.datetime "occurred_at"
    t.datetime "projected_at", null: false
    t.integer "supersedes_projection_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_state"], name: "index_evidence_projections_on_current_state"
    t.index ["projection_type", "external_project_id", "external_subject_id", "projection_version"], name: "idx_evidence_projections_lookup"
    t.index ["source_event_id"], name: "index_evidence_projections_on_source_event_id"
    t.index ["supersedes_projection_id"], name: "index_evidence_projections_on_supersedes_projection_id"
  end

  create_table "external_object_mappings", force: :cascade do |t|
    t.integer "integration_source_id", null: false
    t.string "external_object_type", null: false
    t.string "external_object_id", null: false
    t.string "internal_record_type", null: false
    t.bigint "internal_record_id"
    t.string "external_version"
    t.integer "last_integration_event_id"
    t.datetime "first_seen_at", null: false
    t.datetime "last_seen_at", null: false
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_source_id", "external_object_type", "external_object_id", "internal_record_type"], name: "idx_external_object_mappings_identity", unique: true
    t.index ["integration_source_id"], name: "index_external_object_mappings_on_integration_source_id"
    t.index ["internal_record_type", "internal_record_id"], name: "idx_external_object_mappings_internal"
    t.index ["last_integration_event_id"], name: "index_external_object_mappings_on_last_integration_event_id"
  end

  create_table "integration_deliveries", force: :cascade do |t|
    t.integer "integration_webhook_endpoint_id", null: false
    t.string "event_type", null: false
    t.string "external_id", null: false
    t.json "payload_json", default: {}, null: false
    t.string "payload_digest"
    t.string "idempotency_key", null: false
    t.text "signature"
    t.string "status", default: "pending", null: false
    t.integer "attempt_count", default: 0, null: false
    t.integer "response_status"
    t.text "response_body_excerpt"
    t.datetime "next_attempt_at"
    t.datetime "delivered_at"
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_integration_deliveries_on_external_id", unique: true
    t.index ["idempotency_key"], name: "index_integration_deliveries_on_idempotency_key", unique: true
    t.index ["integration_webhook_endpoint_id"], name: "idx_on_integration_webhook_endpoint_id_2870bd226f"
    t.index ["next_attempt_at"], name: "index_integration_deliveries_on_next_attempt_at"
    t.index ["status"], name: "index_integration_deliveries_on_status"
  end

  create_table "integration_events", force: :cascade do |t|
    t.integer "integration_source_id", null: false
    t.string "external_event_id", null: false
    t.string "event_type", null: false
    t.string "schema_version", null: false
    t.string "external_object_type"
    t.string "external_object_id"
    t.datetime "occurred_at"
    t.datetime "received_at", null: false
    t.text "raw_payload_json", null: false
    t.text "canonical_payload_json", null: false
    t.string "payload_digest", null: false
    t.string "provided_digest"
    t.text "signature"
    t.string "signature_algorithm"
    t.string "signature_status", default: "unchecked", null: false
    t.string "schema_status", default: "unchecked", null: false
    t.string "processing_status", default: "received", null: false
    t.string "processing_error_code"
    t.text "processing_error_message"
    t.integer "attempt_count", default: 0, null: false
    t.datetime "processed_at"
    t.string "operation_external_id"
    t.string "supersedes_event_id"
    t.json "correlation_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type", "occurred_at"], name: "index_integration_events_on_event_type_and_occurred_at"
    t.index ["integration_source_id", "external_event_id"], name: "idx_integration_events_source_external_id", unique: true
    t.index ["integration_source_id"], name: "index_integration_events_on_integration_source_id"
    t.index ["payload_digest"], name: "index_integration_events_on_payload_digest"
    t.index ["processing_status"], name: "index_integration_events_on_processing_status"
  end

  create_table "integration_operations", force: :cascade do |t|
    t.integer "integration_event_id", null: false
    t.string "external_id", null: false
    t.string "operation_type", null: false
    t.string "status", default: "pending", null: false
    t.string "idempotency_key", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "error_code"
    t.text "error_message"
    t.json "result_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_integration_operations_on_external_id", unique: true
    t.index ["idempotency_key"], name: "index_integration_operations_on_idempotency_key", unique: true
    t.index ["integration_event_id"], name: "index_integration_operations_on_integration_event_id"
    t.index ["status"], name: "index_integration_operations_on_status"
  end

  create_table "integration_sources", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.string "environment"
    t.string "status", default: "active", null: false
    t.string "signature_algorithm", default: "hmac_sha256", null: false
    t.text "verification_secret_ciphertext"
    t.text "verification_public_key"
    t.datetime "last_event_at"
    t.json "allowed_event_types", default: [], null: false
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_integration_sources_on_key", unique: true
    t.index ["status"], name: "index_integration_sources_on_status"
  end

  create_table "integration_webhook_endpoints", force: :cascade do |t|
    t.integer "integration_source_id", null: false
    t.string "url", null: false
    t.string "status", default: "active", null: false
    t.text "signing_secret_ciphertext"
    t.json "subscribed_event_types", default: [], null: false
    t.datetime "last_success_at"
    t.datetime "last_failure_at"
    t.json "metadata_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_source_id"], name: "index_integration_webhook_endpoints_on_integration_source_id"
    t.index ["status"], name: "index_integration_webhook_endpoints_on_status"
  end

  create_table "invitations", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string "email", null: false
    t.string "role", null: false
    t.string "token", null: false
    t.datetime "expires_at", precision: nil
    t.integer "invited_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "methodology_migrations", force: :cascade do |t|
    t.integer "avsa_id", null: false
    t.integer "delta_receipt_id"
    t.string "old_methodology", null: false
    t.string "old_version", null: false
    t.string "new_methodology", null: false
    t.string "new_version", null: false
    t.string "status", default: "pending", null: false
    t.decimal "affected_credits", precision: 14, scale: 3, default: "0.0", null: false
    t.text "impact_summary"
    t.json "recalculation_payload", default: {}, null: false
    t.datetime "appended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avsa_id"], name: "index_methodology_migrations_on_avsa_id"
    t.index ["delta_receipt_id"], name: "index_methodology_migrations_on_delta_receipt_id"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.integer "user_id", null: false
    t.string "role", default: "viewer", null: false
    t.datetime "joined_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["role"], name: "index_organization_memberships_on_role"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "legal_name"
    t.string "display_name", null: false
    t.string "slug", null: false
    t.string "organization_type", null: false
    t.string "website"
    t.string "country_code"
    t.string "billing_email"
    t.string "status", default: "active"
    t.boolean "sandbox", default: true
    t.string "data_region", default: "us"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_organizations_on_external_id", unique: true
    t.index ["organization_type"], name: "index_organizations_on_organization_type"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "producer_payments", force: :cascade do |t|
    t.integer "avsa_id", null: false
    t.string "producer_name", null: false
    t.decimal "gross_amount", precision: 12, scale: 2, null: false
    t.decimal "verification_deduction", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "platform_deduction", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "other_deductions", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "net_amount", precision: 12, scale: 2, null: false
    t.string "currency", default: "USD", null: false
    t.string "status", default: "pending", null: false
    t.string "remittance_reference"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avsa_id"], name: "index_producer_payments_on_avsa_id"
  end

  create_table "protocols", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "version", null: false
    t.string "governance_version", null: false
    t.string "status", default: "active", null: false
    t.date "effective_on"
    t.date "retired_on"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_protocols_on_code", unique: true
  end

  create_table "receipt_outboxes", force: :cascade do |t|
    t.integer "integration_event_id", null: false
    t.string "aggregate_type", null: false
    t.bigint "aggregate_id"
    t.string "receipt_type", null: false
    t.string "schema_id", null: false
    t.string "schema_version", default: "1.0.0", null: false
    t.json "canonical_payload_json", default: {}, null: false
    t.string "payload_digest", null: false
    t.string "idempotency_key", null: false
    t.string "status", default: "pending", null: false
    t.integer "attempt_count", default: 0, null: false
    t.integer "receipt_id"
    t.string "receipt_digest"
    t.string "verification_status"
    t.json "verification_result_json", default: {}, null: false
    t.string "last_error_code"
    t.text "last_error_message"
    t.datetime "issued_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregate_type", "aggregate_id"], name: "index_receipt_outboxes_on_aggregate_type_and_aggregate_id"
    t.index ["idempotency_key"], name: "index_receipt_outboxes_on_idempotency_key", unique: true
    t.index ["integration_event_id"], name: "index_receipt_outboxes_on_integration_event_id"
    t.index ["receipt_id"], name: "index_receipt_outboxes_on_receipt_id"
    t.index ["status"], name: "index_receipt_outboxes_on_status"
  end

  create_table "receipts", force: :cascade do |t|
    t.integer "avsa_id", null: false
    t.string "receipt_type", null: false
    t.string "title", null: false
    t.string "lifecycle_state", default: "draft", null: false
    t.string "domain_state"
    t.string "issuer_name"
    t.string "signer_key_id"
    t.string "schema_id"
    t.string "schema_digest"
    t.string "body_digest"
    t.string "evidence_commitment"
    t.string "policy_commitment"
    t.string "trace_commitment"
    t.integer "sequence", null: false
    t.json "parent_receipt_ids", default: [], null: false
    t.text "canonical_encoding_hex"
    t.string "integrity_status", default: "indeterminate", null: false
    t.datetime "signed_at"
    t.datetime "sealed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avsa_id", "sequence"], name: "index_receipts_on_avsa_id_and_sequence", unique: true
    t.index ["avsa_id"], name: "index_receipts_on_avsa_id"
    t.index ["body_digest"], name: "index_receipts_on_body_digest", unique: true
  end

  create_table "schemas", force: :cascade do |t|
    t.bigint "project_id"
    t.string "name", null: false
    t.string "type", null: false
    t.string "version", null: false
    t.text "definition", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "version"], name: "index_schemas_on_name_and_version", unique: true
    t.index ["project_id"], name: "index_schemas_on_project_id"
    t.index ["type"], name: "index_schemas_on_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "role", default: "viewer"
    t.string "status", default: "active"
    t.datetime "last_sign_in_at", precision: nil
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "verification_exceptions", force: :cascade do |t|
    t.integer "avsa_id", null: false
    t.integer "receipt_id"
    t.string "code", null: false
    t.string "severity", null: false
    t.string "status", default: "open", null: false
    t.string "materiality"
    t.text "description", null: false
    t.string "owner"
    t.date "due_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avsa_id"], name: "index_verification_exceptions_on_avsa_id"
    t.index ["receipt_id"], name: "index_verification_exceptions_on_receipt_id"
  end

  create_table "verification_runs", force: :cascade do |t|
    t.integer "avsa_id", null: false
    t.integer "receipt_id"
    t.string "status", null: false
    t.string "verifier_mode", null: false
    t.text "message"
    t.json "checks", default: [], null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avsa_id"], name: "index_verification_runs_on_avsa_id"
    t.index ["receipt_id"], name: "index_verification_runs_on_receipt_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.bigint "project_id"
    t.string "event", null: false
    t.string "url", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_webhooks_on_active"
    t.index ["event"], name: "index_webhooks_on_event"
    t.index ["project_id"], name: "index_webhooks_on_project_id"
  end

  add_foreign_key "agevidence_artifact_engagements", "agevidence_developer_projects", column: "developer_project_id"
  add_foreign_key "agevidence_artifact_engagements", "evidence_bundles"
  add_foreign_key "agevidence_artifact_engagements", "organizations"
  add_foreign_key "agevidence_artifact_orders", "agevidence_artifact_engagements", column: "artifact_engagement_id"
  add_foreign_key "agevidence_artifact_orders", "agevidence_developer_projects", column: "developer_project_id"
  add_foreign_key "agevidence_artifact_orders", "agevidence_pricing_quotes", column: "pricing_quote_id"
  add_foreign_key "agevidence_artifact_orders", "evidence_bundles"
  add_foreign_key "agevidence_artifact_orders", "organizations"
  add_foreign_key "agevidence_country_adapters", "agevidence_country_claim_policies", column: "country_claim_policy_id"
  add_foreign_key "agevidence_country_adapters", "agevidence_country_data_policies", column: "country_data_policy_id"
  add_foreign_key "agevidence_country_adapters", "agevidence_country_method_versions", column: "country_method_version_id"
  add_foreign_key "agevidence_country_adapters", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_adapters", "agevidence_country_verification_profiles", column: "country_verification_profile_id"
  add_foreign_key "agevidence_country_adapters", "receipts", column: "commitment_receipt_id"
  add_foreign_key "agevidence_country_claim_policies", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_data_policies", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_determinations", "agevidence_country_adapters", column: "country_adapter_id"
  add_foreign_key "agevidence_country_determinations", "agevidence_country_determinations", column: "supersedes_id"
  add_foreign_key "agevidence_country_determinations", "agevidence_country_method_versions", column: "country_method_version_id"
  add_foreign_key "agevidence_country_determinations", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_determinations", "agevidence_developer_projects", column: "developer_project_id"
  add_foreign_key "agevidence_country_determinations", "receipts"
  add_foreign_key "agevidence_country_institutions", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_method_versions", "agevidence_country_methods", column: "country_method_id"
  add_foreign_key "agevidence_country_methods", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_pilots", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_registries", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_country_verification_profiles", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_developer_accounts", "organizations"
  add_foreign_key "agevidence_developer_projects", "agevidence_country_programs", column: "country_program_id"
  add_foreign_key "agevidence_developer_projects", "agevidence_country_programs", column: "primary_country_program_id"
  add_foreign_key "agevidence_developer_projects", "agevidence_developer_accounts", column: "developer_account_id"
  add_foreign_key "agevidence_developer_projects", "avsas"
  add_foreign_key "agevidence_developer_projects", "organizations"
  add_foreign_key "agevidence_developer_projects", "protocols"
  add_foreign_key "agevidence_evidence_candidates", "agevidence_model_runs", column: "model_run_id"
  add_foreign_key "agevidence_evidence_candidates", "evidence_items"
  add_foreign_key "agevidence_evidence_candidates", "receipts"
  add_foreign_key "agevidence_evidence_gaps", "agevidence_model_runs", column: "model_run_id"
  add_foreign_key "agevidence_model_runs", "agevidence_country_adapters", column: "country_adapter_id"
  add_foreign_key "agevidence_model_runs", "agevidence_developer_projects", column: "developer_project_id"
  add_foreign_key "agevidence_model_runs", "agevidence_model_adapters", column: "model_adapter_id"
  add_foreign_key "agevidence_model_runs", "organizations"
  add_foreign_key "agevidence_model_runs", "receipts"
  add_foreign_key "agevidence_pricing_quotes", "agevidence_developer_projects", column: "developer_project_id"
  add_foreign_key "agevidence_pricing_quotes", "organizations"
  add_foreign_key "agevidence_reliance_events", "agevidence_artifact_engagements", column: "artifact_engagement_id"
  add_foreign_key "agevidence_reliance_events", "evidence_bundles"
  add_foreign_key "agevidence_reliance_events", "organizations"
  add_foreign_key "agevidence_review_decisions", "agevidence_evidence_candidates", column: "evidence_candidate_id"
  add_foreign_key "agevidence_review_decisions", "receipts"
  add_foreign_key "agevidence_source_records", "agevidence_developer_projects", column: "developer_project_id"
  add_foreign_key "agevidence_source_records", "evidence_projections"
  add_foreign_key "agevidence_source_records", "integration_events", column: "source_event_id"
  add_foreign_key "agevidence_source_records", "organizations"
  add_foreign_key "agevidence_source_records", "receipts"
  add_foreign_key "api_keys", "users"
  add_foreign_key "api_logs", "api_keys"
  add_foreign_key "avsas", "protocols"
  add_foreign_key "campaign_accounts", "agevidence_developer_accounts", column: "developer_account_id"
  add_foreign_key "campaign_activation_paths", "campaign_accounts"
  add_foreign_key "campaign_adapter_readiness_assessments", "campaign_country_programs"
  add_foreign_key "campaign_capability_attributions", "campaign_accounts"
  add_foreign_key "campaign_capability_attributions", "campaign_commercial_handoffs"
  add_foreign_key "campaign_commercial_handoffs", "campaign_accounts"
  add_foreign_key "campaign_commercial_handoffs", "campaign_technical_qualifications"
  add_foreign_key "campaign_contact_refs", "campaign_accounts"
  add_foreign_key "campaign_institution_profiles", "campaign_country_programs"
  add_foreign_key "campaign_obligation_profiles", "campaign_country_programs"
  add_foreign_key "campaign_technical_qualifications", "agevidence_developer_projects", column: "developer_project_id"
  add_foreign_key "campaign_technical_qualifications", "campaign_accounts"
  add_foreign_key "campaign_touches", "campaign_accounts"
  add_foreign_key "campaign_touches", "campaign_contact_refs"
  add_foreign_key "claim_groups", "avsas"
  add_foreign_key "claim_shares", "claim_groups"
  add_foreign_key "commercial_order_events", "agevidence_artifact_orders", column: "order_id"
  add_foreign_key "evidence_bundles", "agevidence_country_adapters", column: "country_adapter_id"
  add_foreign_key "evidence_bundles", "agevidence_country_claim_policies", column: "country_claim_policy_id"
  add_foreign_key "evidence_bundles", "agevidence_country_data_policies", column: "country_data_policy_id"
  add_foreign_key "evidence_bundles", "agevidence_country_determinations", column: "country_determination_id"
  add_foreign_key "evidence_bundles", "agevidence_country_verification_profiles", column: "country_verification_profile_id"
  add_foreign_key "evidence_bundles", "avsas"
  add_foreign_key "evidence_bundles", "receipts", column: "acceptance_receipt_id"
  add_foreign_key "evidence_items", "receipts"
  add_foreign_key "evidence_projections", "evidence_projections", column: "supersedes_projection_id"
  add_foreign_key "evidence_projections", "integration_events", column: "source_event_id"
  add_foreign_key "external_object_mappings", "integration_events", column: "last_integration_event_id"
  add_foreign_key "external_object_mappings", "integration_sources"
  add_foreign_key "integration_deliveries", "integration_webhook_endpoints"
  add_foreign_key "integration_events", "integration_sources"
  add_foreign_key "integration_operations", "integration_events"
  add_foreign_key "integration_webhook_endpoints", "integration_sources"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "methodology_migrations", "avsas"
  add_foreign_key "methodology_migrations", "receipts", column: "delta_receipt_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "producer_payments", "avsas"
  add_foreign_key "receipt_outboxes", "integration_events"
  add_foreign_key "receipt_outboxes", "receipts"
  add_foreign_key "receipts", "avsas"
  add_foreign_key "verification_exceptions", "avsas"
  add_foreign_key "verification_exceptions", "receipts"
  add_foreign_key "verification_runs", "avsas"
  add_foreign_key "verification_runs", "receipts"
end
