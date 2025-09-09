class Plan < ApplicationRecord
  # Relationships
  has_many :subscriptions, dependent: :destroy
  has_many :users, through: :subscriptions

  # Atributos para controle de sincronização
  attr_accessor :syncing_from_stripe

  # Validations
  validates :name, :price_cents, presence: true
  validates :name, uniqueness: { case_sensitive: false }, unless: :skip_uniqueness_validation?
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
    
    # Se apenas campos técnicos estão sendo atualizados, usar update_columns
    if attributes.keys.all? { |key| [:stripe_price_id, :price_cents].include?(key.to_sym) }
      update_columns(attributes)
    else
      update!(attributes)
    end
  ensure
    self.syncing_from_stripe = false
  end

  # Método alternativo que força update sem validações
  def force_update_from_stripe!(attributes = {})
    update_columns(attributes.merge(updated_at: Time.current))
  end

  private

  def syncing_from_stripe?
    syncing_from_stripe == true
  end

  def skip_uniqueness_validation?
    # Pula validação durante sincronização do Stripe
    syncing_from_stripe == true || 
    # Ou se é uma atualização de um registro existente com o mesmo nome
    (persisted? && !name_changed?) ||
    # Ou se estamos apenas atualizando o stripe_price_id
    (persisted? && changed_attributes.keys == ['stripe_price_id'])
  end
end
