class Plan < ApplicationRecord
  # Relationships
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  # Validations
  validates :name, :price_cents, presence: true
  validates :name, uniqueness: { case_sensitive: false }
  validates :price_cents, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :popular, -> { where(popular: true) }

  # Methods
  def price
    price_cents / 100.0
  end

  def price_formatted
    sprintf("R$ %.2f", price_cents / 100.0)
  end

  def unlimited_links?
    max_links == -1
  end

  def self.starter
    find_by(name: "Afiliado Starter")
  end

  def self.pro
    find_by(name: "Afiliado Pro")
  end

  def self.elite
    find_by(name: "Afiliado Elite")
  end
end
