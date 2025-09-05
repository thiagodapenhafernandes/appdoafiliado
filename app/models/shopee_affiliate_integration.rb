class ShopeeAffiliateIntegration < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :affiliate_conversions, dependent: :destroy

  # Encryption for sensitive data - only for individual auth
  attr_encrypted :secret, key: Rails.application.credentials.secret_key_base&.first(32)
  attr_encrypted :access_token, key: Rails.application.credentials.secret_key_base&.first(32)
  attr_encrypted :refresh_token, key: Rails.application.credentials.secret_key_base&.first(32)

  # Validations
  validates :app_id, presence: true, uniqueness: { scope: :user_id }, if: :individual_auth?
  validates :secret, presence: true, if: :individual_auth?
  validates :shopee_user_id, presence: true, uniqueness: { scope: :user_id }, if: :centralized_auth?
  validates :access_token, presence: true, if: :centralized_auth?
  validates :market, inclusion: { in: %w[BR MX CO CL US SG MY TH VN PH TW] }
  validates :endpoint, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }
  validates :auth_type, inclusion: { in: %w[individual centralized oauth] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_market, ->(market) { where(market: market) }
  scope :centralized, -> { where(auth_type: 'centralized') }
  scope :individual, -> { where(auth_type: 'individual') }

  # Callbacks
  before_validation :set_defaults

  # Instance methods
  def connected?
    case auth_type
    when 'individual'
      app_id.present? && secret.present? && active?
    when 'centralized', 'oauth'
      shopee_user_id.present? && access_token.present? && active? && !token_expired? && master_config_available?
    else
      false
    end
  end

  def individual_auth?
    auth_type == 'individual'
  end

  def centralized_auth?
    auth_type == 'centralized'
  end

  def oauth_auth?
    auth_type == 'oauth'
  end

  def master_config_available?
    return true if individual_auth?
    
    config = ShopeeMasterConfig.active_for_market(market)
    config&.configured?
  end

  def master_config
    return nil if individual_auth?
    
    ShopeeMasterConfig.active_for_market(market)
  end

  def token_expired?
    token_expires_at.present? && token_expires_at < Time.current
  end

  def client
    case auth_type
    when 'individual'
      ShopeeAffiliate::Client.new(self)
    when 'centralized', 'oauth'
      ShopeeAffiliate::CentralizedClient.new(self)
    end
  end

  def last_sync_success?
    last_error.blank? && last_sync_at.present?
  end

  def sync_overdue?
    return true if last_sync_at.blank?
    last_sync_at < 2.hours.ago
  end

  def update_sync_status!(success: true, error: nil)
    update!(
      last_sync_at: Time.current,
      sync_count: sync_count + 1,
      last_error: success ? nil : error
    )
  end

  # Test connection to Shopee API
  def test_connection
    return false unless connected?
    
    begin
      case auth_type
      when 'individual'
        ShopeeAffiliate::Client.new(self).test_connection
      when 'centralized', 'oauth'
        ShopeeAffiliate::CentralizedClient.new(self).test_connection
      end
    rescue => e
      update!(last_error: "Connection test failed: #{e.message}")
      false
    end
  end

  # Check if user can use centralized auth for their market
  def self.centralized_available_for_market?(market)
    ShopeeMasterConfig.active_for_market(market)&.configured? || false
  end

  # Create a centralized integration for user
  def self.create_centralized!(user:, market: 'BR', shopee_user_id:, access_token:, refresh_token: nil, token_expires_at: nil)
    config = ShopeeMasterConfig.active_for_market(market)
    raise "Master configuration not available for market #{market}" unless config&.configured?

    create!(
      user: user,
      market: market,
      endpoint: config.endpoint,
      auth_type: 'centralized',
      shopee_user_id: shopee_user_id,
      access_token: access_token,
      refresh_token: refresh_token,
      token_expires_at: token_expires_at,
      active: true
    )
  end

  private

  def set_defaults
    self.market ||= 'BR'
    self.auth_type ||= determine_default_auth_type
    
    # Set endpoint based on market and auth type
    if centralized_auth? && (config = ShopeeMasterConfig.active_for_market(market))
      self.endpoint = config.endpoint
    else
      self.endpoint ||= default_endpoint_for_market
    end
    
    self.active = true if active.nil?
    self.sync_count ||= 0
  end

  def determine_default_auth_type
    # Use centralized if available for market, otherwise individual
    if ShopeeMasterConfig.active_for_market(market || 'BR')&.configured?
      'centralized'
    else
      'individual'
    end
  end

  def default_endpoint_for_market
    case market
    when 'BR'
      'https://open-api.affiliate.shopee.com.br/graphql'
    when 'MX'
      'https://open-api.affiliate.shopee.com.mx/graphql'
    when 'CO'
      'https://open-api.affiliate.shopee.com.co/graphql'
    when 'CL'
      'https://open-api.affiliate.shopee.cl/graphql'
    else
      'https://open-api.affiliate.shopee.com.br/graphql' # Default to BR
    end
  end
end
