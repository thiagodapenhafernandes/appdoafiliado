class CreateAffiliateConversions < ActiveRecord::Migration[7.1]
  def change
    create_table :affiliate_conversions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :external_id, null: false # chave única da API
      t.string :order_id
      t.string :item_id
      t.string :category
      t.string :channel
      t.string :sub_id
      t.integer :commission_cents, default: 0
      t.string :currency, default: 'BRL'
      t.integer :quantity, default: 1
      t.datetime :click_time
      t.datetime :conversion_time
      t.string :status
      t.string :source, default: 'shopee_api' # vs 'csv'
      t.json :raw_data # dados originais da API
      t.decimal :purchase_value, precision: 10, scale: 2
      t.decimal :commission_rate, precision: 5, scale: 2

      t.timestamps
    end

    # Índices para performance e constraints
    add_index :affiliate_conversions, [:user_id, :external_id], unique: true
    add_index :affiliate_conversions, :sub_id
    add_index :affiliate_conversions, :conversion_time
    add_index :affiliate_conversions, :status
    add_index :affiliate_conversions, :source
    add_index :affiliate_conversions, :order_id
  end
end
