class CreateWebsiteClickImports < ActiveRecord::Migration[6.1]
  def change
    create_table :website_click_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :file_name, null: false
      t.datetime :imported_at, null: false
      t.timestamps
    end
    add_reference :website_clicks, :website_click_import, foreign_key: true
  end
end
