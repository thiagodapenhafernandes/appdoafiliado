class AddAdvancedTrackingFieldsToWebsiteClicks < ActiveRecord::Migration[7.0]
  def change
    add_reference :website_clicks, :link, foreign_key: true
    add_column :website_clicks, :ip_address, :inet
    add_column :website_clicks, :user_agent, :text
  end
end
