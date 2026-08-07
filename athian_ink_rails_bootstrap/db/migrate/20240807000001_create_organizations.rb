class CreateOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :external_id, null: false
      t.string :legal_name
      t.string :display_name, null: false
      t.string :slug, null: false
      t.string :organization_type, null: false
      t.string :website
      t.string :country_code
      t.string :billing_email
      t.string :status, default: "active"
      t.boolean :sandbox, default: true
      t.string :data_region, default: "us"
      
      t.timestamps
      
      t.index :external_id, unique: true
      t.index :slug, unique: true
      t.index :organization_type
    end

    # Add organization_id to existing Agevidence records (Phase 1 batch 1)
    add_reference :agevidence_developer_projects, :organization, foreign_key: true, index: true
    add_reference :agevidence_source_records, :organization, foreign_key: true, index: true
    add_reference :agevidence_model_runs, :organization, foreign_key: true, index: true
    add_reference :agevidence_pricing_quotes, :organization, foreign_key: true, index: true
    add_reference :agevidence_artifact_orders, :organization, foreign_key: true, index: true
    add_reference :agevidence_artifact_engagements, :organization, foreign_key: true, index: true
    add_reference :agevidence_reliance_events, :organization, foreign_key: true, index: true
  end
end
