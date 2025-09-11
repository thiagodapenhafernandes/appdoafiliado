class WebsiteClickImport < ApplicationRecord
  belongs_to :user
  has_many :website_clicks, dependent: :destroy

  validates :imported_at, presence: true
  validates :file_name, presence: true
end
