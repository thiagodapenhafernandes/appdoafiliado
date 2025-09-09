class Plan < ApplicationRecord
  # Relationships
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  # Atributos para controle de sincronização
  attr_accessor :syncing_from_stripe

  # Validations
  validates :name, :price_cents, presence: true
  validates :name, uniqueness: { case_sensitive: false }, unless: :syncing_from_stripe?
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

  # Método para sincronização sem validações conflitantes
  def sync_from_stripe!(attributes = {})
    self.syncing_from_stripe = true
    update!(attributes)
  ensure
    self.syncing_from_stripe = false
  end

  private

  def syncing_from_stripe?
    syncing_from_stripe == true
  end
end
