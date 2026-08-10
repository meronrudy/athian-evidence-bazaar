class CreateDeveloperDashboardSupportTables < ActiveRecord::Migration[7.1]
  def change
    create_table :api_keys do |t|
      t.references :user, foreign_key: true
      t.bigint :project_id
      t.string :name, null: false
      t.string :key, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :api_keys, :key, unique: true
    add_index :api_keys, :project_id

    create_table :api_logs do |t|
      t.references :api_key, foreign_key: true
      t.string :endpoint, null: false
      t.string :method, null: false
      t.integer :status, null: false
      t.string :request_id, null: false
      t.decimal :duration, precision: 10, scale: 4
      t.timestamps
    end
    add_index :api_logs, :endpoint
    add_index :api_logs, :status
    add_index :api_logs, :request_id

    create_table :webhooks do |t|
      t.bigint :project_id
      t.string :event, null: false
      t.string :url, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :webhooks, :project_id
    add_index :webhooks, :event
    add_index :webhooks, :active

    create_table :schemas do |t|
      t.bigint :project_id
      t.string :name, null: false
      t.string :type, null: false
      t.string :version, null: false
      t.text :definition, null: false
      t.timestamps
    end
    add_index :schemas, :project_id
    add_index :schemas, %i[name version], unique: true
    add_index :schemas, :type
  end
end
