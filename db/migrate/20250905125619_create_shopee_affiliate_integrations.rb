class CreateShopeeAffiliateIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :shopee_affiliate_integrations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :app_id, null: false
      t.text :encrypted_secret
      t.string :encrypted_secret_iv
      t.string :market, default: 'BR'
      t.string :endpoint, default: 'https://open-api.affiliate.shopee.com.br/graphql'
      t.datetime :last_sync_at
      t.boolean :active, default: true
      t.text :last_error # para debug de problemas na API
      t.integer :sync_count, default: 0 # contador de sincronizações

      t.timestamps
    end

    add_index :shopee_affiliate_integrations, [:user_id], unique: true, name: 'index_shopee_integrations_on_user_id'
    add_index :shopee_affiliate_integrations, :app_id, name: 'index_shopee_integrations_on_app_id'
  end
end
