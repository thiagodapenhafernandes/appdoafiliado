# db/migrate/xxxx_create_shopee_master_configs.rb
class CreateShopeeMasterConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :shopee_master_configs do |t|
      t.string :market, null: false, default: 'BR'
      t.text :endpoint, null: false
      t.text :encrypted_master_app_id
      t.string :encrypted_master_app_id_iv
      t.text :encrypted_master_secret
      t.string :encrypted_master_secret_iv
      t.boolean :active, default: false
      t.integer :rate_limit_per_minute, default: 100
      t.integer :rate_limit_per_hour, default: 5000
      t.datetime :last_tested_at
      t.text :last_test_result
      t.text :notes
      
      t.timestamps
    end

    add_index :shopee_master_configs, :market
    add_index :shopee_master_configs, :active
    add_index :shopee_master_configs, [:market, :active]
  end
end
