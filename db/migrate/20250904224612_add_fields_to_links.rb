class AddFieldsToLinks < ActiveRecord::Migration[7.1]
  def change
    add_column :links, :name, :string
    add_column :links, :custom_slug, :string
    add_column :links, :tags, :text
    add_column :links, :expires_at, :datetime
    add_column :links, :advanced_tracking, :boolean
  end
end
