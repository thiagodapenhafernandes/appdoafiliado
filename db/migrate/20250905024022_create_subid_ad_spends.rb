class CreateSubidAdSpends < ActiveRecord::Migration[7.1]
  def change
    create_table :subid_ad_spends do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subid
      t.decimal :ad_spend
      t.decimal :total_investment
      t.date :period_start
      t.date :period_end

      t.timestamps
    end
  end
end
