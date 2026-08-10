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

    # Add organization_id to existing Agevidence records when those tables
    # already exist. Fresh SQLite installs create the Agevidence tables later.
    %i[
      agevidence_developer_projects
      agevidence_source_records
      agevidence_model_runs
      agevidence_pricing_quotes
      agevidence_artifact_orders
      agevidence_artifact_engagements
      agevidence_reliance_events
    ].each do |table_name|
      next unless table_exists?(table_name)
      next if column_exists?(table_name, :organization_id)

      add_reference table_name, :organization, foreign_key: true, index: true
    end
  end
end
