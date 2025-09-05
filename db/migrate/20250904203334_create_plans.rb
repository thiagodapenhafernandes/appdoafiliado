class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false
      t.string :currency, default: 'BRL'
      t.string :stripe_price_id
      t.integer :max_links
      t.json :features
      t.boolean :popular, default: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :plans, :name
    add_index :plans, :active
    add_index :plans, :popular
  end
end
