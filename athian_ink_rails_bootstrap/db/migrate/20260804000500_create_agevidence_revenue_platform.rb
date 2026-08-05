class CreateAgevidenceRevenuePlatform < ActiveRecord::Migration[7.1]
  def change
    create_table :agevidence_api_clients do |t|
      t.references :developer_account, null: false, foreign_key: { to_table: :agevidence_developer_accounts }
      t.string :name, null: false
      t.string :token_prefix, null: false
      t.string :token_digest, null: false
      t.text :scopes, null: false, default: "[]"
      t.string :status, null: false, default: "active"
      t.integer :rate_limit_per_minute, null: false, default: 120
      t.datetime :last_used_at
      t.datetime :expires_at
      t.timestamps
    end
    add_index :agevidence_api_clients, :token_prefix, unique: true

    create_table :agevidence_price_books do |t|
      t.string :product_code, null: false
      t.string :version, null: false
      t.string :name, null: false
      t.string :currency, null: false, default: "usd"
      t.string :billing_model, null: false
      t.integer :base_amount_cents, null: false, default: 0
      t.integer :minimum_amount_cents, null: false, default: 0
      t.string :unit_name
      t.integer :included_units, null: false, default: 0
      t.integer :overage_amount_cents, null: false, default: 0
      t.text :dimensions, null: false, default: "{}"
      t.boolean :active, null: false, default: true
      t.datetime :effective_at, null: false
      t.datetime :retired_at
      t.timestamps
    end
    add_index :agevidence_price_books, %i[product_code version], unique: true
    add_index :agevidence_price_books, %i[active effective_at]

    create_table :agevidence_billing_accounts do |t|
      t.references :developer_account, null: false, foreign_key: { to_table: :agevidence_developer_accounts }, index: { unique: true }
      t.string :provider, null: false, default: "stripe"
      t.string :customer_id
      t.string :status, null: false, default: "pending"
      t.string :billing_email
      t.string :tax_country
      t.string :currency, null: false, default: "usd"
      t.integer :payment_terms_days, null: false, default: 0
      t.integer :monthly_commitment_cents, null: false, default: 0
      t.text :metadata, null: false, default: "{}"
      t.timestamps
    end
    add_index :agevidence_billing_accounts, %i[provider customer_id], unique: true

    create_table :agevidence_subscriptions do |t|
      t.references :billing_account, null: false, foreign_key: { to_table: :agevidence_billing_accounts }
      t.references :price_book, null: false, foreign_key: { to_table: :agevidence_price_books }
      t.string :provider_subscription_id
      t.string :status, null: false, default: "pending"
      t.integer :quantity, null: false, default: 1
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, null: false, default: false
      t.text :metadata, null: false, default: "{}"
      t.timestamps
    end
    add_index :agevidence_subscriptions, :provider_subscription_id, unique: true

    create_table :agevidence_artifact_orders do |t|
      t.references :developer_account, null: false, foreign_key: { to_table: :agevidence_developer_accounts }
      t.references :developer_project, foreign_key: { to_table: :agevidence_developer_projects }
      t.references :evidence_bundle, foreign_key: true
      t.references :price_book, null: false, foreign_key: { to_table: :agevidence_price_books }
      t.string :external_id, null: false
      t.string :idempotency_key, null: false
      t.string :product_code, null: false
      t.string :status, null: false, default: "quoted"
      t.string :currency, null: false, default: "usd"
      t.text :scope, null: false, default: "{}"
      t.text :pricing_input, null: false, default: "{}"
      t.text :pricing_breakdown, null: false, default: "{}"
      t.integer :quoted_amount_cents, null: false
      t.integer :final_amount_cents
      t.string :checkout_provider
      t.string :checkout_session_id
      t.string :payment_intent_id
      t.datetime :paid_at
      t.datetime :fulfilled_at
      t.datetime :expires_at
      t.timestamps
    end
    add_index :agevidence_artifact_orders, :external_id, unique: true
    add_index :agevidence_artifact_orders, %i[developer_account_id idempotency_key], unique: true, name: "idx_agev_orders_account_idempotency"
    add_index :agevidence_artifact_orders, :checkout_session_id, unique: true

    create_table :agevidence_usage_events do |t|
      t.references :developer_account, null: false, foreign_key: { to_table: :agevidence_developer_accounts }
      t.references :api_client, foreign_key: { to_table: :agevidence_api_clients }
      t.references :artifact_order, foreign_key: { to_table: :agevidence_artifact_orders }
      t.string :event_type, null: false
      t.string :product_code, null: false
      t.decimal :quantity, precision: 20, scale: 6, null: false, default: 1
      t.string :unit, null: false
      t.string :idempotency_key, null: false
      t.datetime :occurred_at, null: false
      t.text :metadata, null: false, default: "{}"
      t.timestamps
    end
    add_index :agevidence_usage_events, %i[developer_account_id idempotency_key], unique: true, name: "idx_agev_usage_account_idempotency"
    add_index :agevidence_usage_events, %i[developer_account_id product_code occurred_at], name: "idx_agev_usage_rollup"

    create_table :agevidence_webhook_events do |t|
      t.string :provider, null: false
      t.string :event_id, null: false
      t.string :event_type, null: false
      t.string :status, null: false, default: "received"
      t.text :payload, null: false
      t.datetime :processed_at
      t.text :failure_reason
      t.timestamps
    end
    add_index :agevidence_webhook_events, %i[provider event_id], unique: true
  end
end
