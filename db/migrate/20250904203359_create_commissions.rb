class CreateCommissions < ActiveRecord::Migration[7.1]
  def change
    create_table :commissions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_id, null: false
      t.string :sub_id
      t.string :channel
      t.decimal :commission_amount, precision: 10, scale: 2
      t.decimal :sale_amount, precision: 10, scale: 2
      t.string :order_status
      t.string :commission_type
      t.string :product_name, limit: 500
      t.string :category
      t.datetime :order_date
      t.datetime :commission_date

      t.timestamps
    end

    add_index :commissions, :order_id
    add_index :commissions, :channel
    add_index :commissions, :order_date
    add_index :commissions, :commission_date
    add_index :commissions, [:user_id, :order_id], unique: true
  end
end
