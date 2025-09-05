# db/migrate/xxxx_add_centralized_auth_to_shopee_integrations.rb
class AddCentralizedAuthToShopeeIntegrations < ActiveRecord::Migration[7.1]
  def change
    add_column :shopee_affiliate_integrations, :shopee_user_id, :string
    add_column :shopee_affiliate_integrations, :encrypted_access_token, :text
    add_column :shopee_affiliate_integrations, :encrypted_access_token_iv, :string
    add_column :shopee_affiliate_integrations, :encrypted_refresh_token, :text
    add_column :shopee_affiliate_integrations, :encrypted_refresh_token_iv, :string
    add_column :shopee_affiliate_integrations, :token_expires_at, :datetime
    add_column :shopee_affiliate_integrations, :auth_type, :string, default: 'individual'
    
    add_index :shopee_affiliate_integrations, :shopee_user_id
    add_index :shopee_affiliate_integrations, :auth_type
  end
end
