class CreateCountryPrograms < ActiveRecord::Migration[7.1]
  def change
    create_table :country_programs do |t|
      t.string :name, null: false
      t.string :country_code, null: false
      t.text :description
      t.string :status, default: 'active', null: false
      t.integer :adapter_count, default: 0
      t.integer :profile_count, default: 0
      t.timestamps
    end

    add_index :country_programs, [:country_code]
    add_index :country_programs, :status
  end
end