class CreateWebsiteClicks < ActiveRecord::Migration[7.1]
  def change
    create_table :website_clicks do |t|
      t.string :click_id
      t.datetime :click_time
      t.string :region
      t.string :sub_id
      t.string :referrer
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
