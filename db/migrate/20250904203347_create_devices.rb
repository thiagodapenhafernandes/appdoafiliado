class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :device_id, null: false
      t.string :device_type
      t.string :browser
      t.string :os
      t.inet :ip_address
      t.text :user_agent
      t.datetime :last_seen_at
      t.boolean :trusted, default: false

      t.timestamps
    end

    add_index :devices, :device_id, unique: true
    add_index :devices, :last_seen_at
    add_index :devices, :trusted
  end
end
