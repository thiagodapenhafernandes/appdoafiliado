# app/models/shopee_master_config.rb
class ShopeeMasterConfig < ApplicationRecord
  # Encryption for master credentials
  attr_encrypted :master_app_id, key: Rails.application.credentials.secret_key_base&.first(32)
  attr_encrypted :master_secret, key: Rails.application.credentials.secret_key_base&.first(32)

  # Validations
  validates :market, presence: true, inclusion: { in: %w[BR US SG MY TH VN PH TW] }
  validates :endpoint, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :master_app_id, presence: true
  validates :master_secret, presence: true
  validates :rate_limit_per_minute, presence: true, numericality: { greater_than: 0 }
  validates :rate_limit_per_hour, presence: true, numericality: { greater_than: 0 }

    # Scopes
  scope :active, -> { where(active: true) }
  scope :for_market, ->(market) { where(market: market) }
  scope :configured, -> { where.not(encrypted_master_app_id: [nil, ''], encrypted_master_secret: [nil, '']) }

  # Class methods
  def self.active_for_market(market)
    active.for_market(market).configured.first
  end

  # Callbacks
  before_validation :set_defaults

  # Class methods
  def self.active_for_market(market)
    active.for_market(market).configured.first
  end

  # Instance methods
  def configured?
    master_app_id.present? && master_secret.present? && active?
  end

  def test_connection
    return false unless configured?

    client = ShopeeAffiliate::MasterClient.new(self)
    client.test_connection
  rescue => e
    Rails.logger.error "Master config test failed: #{e.message}"
    false
  end

  def within_rate_limits?
    # Verificar se não ultrapassou limites de requests
    current_minute_requests = ShopeeApiRequest.where(
      created_at: 1.minute.ago..Time.current
    ).count

    current_hour_requests = ShopeeApiRequest.where(
      created_at: 1.hour.ago..Time.current
    ).count

    current_minute_requests < rate_limit_per_minute && 
    current_hour_requests < rate_limit_per_hour
  end

  private

  def set_defaults
    self.market ||= 'BR'
    self.endpoint ||= 'https://open-api.affiliate.shopee.com.br/graphql'
    self.active = false if active.nil?
    self.rate_limit_per_minute ||= 100
    self.rate_limit_per_hour ||= 5000
  end
end
