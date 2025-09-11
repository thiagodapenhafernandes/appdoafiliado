class AddUniqueIndexToWebsiteClicksOnUserIdAndClickId < ActiveRecord::Migration[7.0]
  def change
    add_index :website_clicks, [:user_id, :click_id], unique: true
  end
end
