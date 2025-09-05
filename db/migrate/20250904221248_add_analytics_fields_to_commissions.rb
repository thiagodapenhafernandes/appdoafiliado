class AddAnalyticsFieldsToCommissions < ActiveRecord::Migration[7.1]
  def change
    add_column :commissions, :payment_id, :string
    add_column :commissions, :completion_time, :datetime
    add_column :commissions, :click_time, :datetime
    add_column :commissions, :store_name, :string
    add_column :commissions, :store_id, :string
    add_column :commissions, :store_type, :string
    add_column :commissions, :item_id, :string
    add_column :commissions, :item_name, :string
    add_column :commissions, :product_type, :string
    add_column :commissions, :category_l1, :string
    add_column :commissions, :category_l2, :string
    add_column :commissions, :category_l3, :string
    add_column :commissions, :price, :decimal
    add_column :commissions, :quantity, :integer
    add_column :commissions, :purchase_value, :decimal
    add_column :commissions, :refund_value, :decimal
    add_column :commissions, :shopee_commission_rate, :decimal
    add_column :commissions, :shopee_commission, :decimal
    add_column :commissions, :seller_commission_rate, :decimal
    add_column :commissions, :seller_commission, :decimal
    add_column :commissions, :total_item_commission, :decimal
    add_column :commissions, :total_order_commission, :decimal
    add_column :commissions, :affiliate_commission, :decimal
    add_column :commissions, :affiliate_status, :string
    add_column :commissions, :attribution_type, :string
    add_column :commissions, :buyer_status, :string
    add_column :commissions, :sub_id1, :string
    add_column :commissions, :sub_id2, :string
    add_column :commissions, :sub_id3, :string
    add_column :commissions, :sub_id4, :string
    add_column :commissions, :sub_id5, :string
  end
end
