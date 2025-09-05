class CreateLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :links do |t|
      t.string :short_code, null: false
      t.text :original_url, null: false
      t.string :title
      t.text :description
      t.integer :clicks_count, default: 0
      t.boolean :active, default: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :links, :short_code, unique: true
    add_index :links, :active
    add_index :links, :clicks_count
  end
end
