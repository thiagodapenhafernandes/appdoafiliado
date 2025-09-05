# db/migrate/xxxx_create_shopee_api_requests.rb
class CreateShopeeApiRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :shopee_api_requests do |t|
      t.references :user, null: true, foreign_key: true
      t.references :shopee_master_config, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :method, null: false
      t.integer :status_code, null: false
      t.integer :response_time_ms
      t.text :error_message
      t.json :request_params
      
      t.timestamps
    end

    add_index :shopee_api_requests, :created_at
    add_index :shopee_api_requests, :status_code
    add_index :shopee_api_requests, [:user_id, :created_at]
    add_index :shopee_api_requests, [:shopee_master_config_id, :created_at]
  end
end
