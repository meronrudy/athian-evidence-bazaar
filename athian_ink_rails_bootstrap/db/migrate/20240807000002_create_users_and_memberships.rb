class CreateUsersAndMemberships < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.string :role, default: "viewer"
      t.string :status, default: "active"
      t.datetime :last_sign_in_at
      t.string :provider
      t.string :uid

      t.timestamps

      t.index :email, unique: true
    end

    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "viewer"
      t.datetime :joined_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps

      t.index [:organization_id, :user_id], unique: true
      t.index :role
    end

    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :email, null: false
      t.string :role, null: false
      t.string :token, null: false
      t.datetime :expires_at
      t.references :invited_by, foreign_key: { to_table: :users }

      t.timestamps

      t.index :token, unique: true
      t.index :email
    end

    # Add temporary compatibility column
    add_reference :agevidence_developer_accounts, :organization, foreign_key: true, index: true
  end
end
