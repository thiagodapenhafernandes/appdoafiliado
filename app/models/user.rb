class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role constants
  ROLES = %w[user admin super_admin].freeze

  # Enum for roles
  enum role: {
    user: 'user',
    admin: 'admin', 
    super_admin: 'super_admin'
  }, _default: 'user'

  # Relationships
  has_many :links, dependent: :destroy
  has_many :commissions, dependent: :destroy
  has_many :website_clicks, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :subid_ad_spends, dependent: :destroy
  has_one :shopee_affiliate_integration, dependent: :destroy
  has_many :affiliate_conversions, dependent: :destroy
  belongs_to :subscription, optional: true

  # Validations
  validates :first_name, :last_name, presence: true

  # Callbacks
  after_create :set_trial_period

  # Methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def on_trial?
    trial_ends_at&.future?
  end

  def trial_days_remaining
    return 0 unless on_trial?
    ((trial_ends_at - Time.current) / 1.day).ceil
  end

  def active_subscription?
    sub = current_subscription

    if sub.present?
      return true unless sub.respond_to?(:status)
      return true if %w[active trialing].include?(sub.status)
    end

    on_trial?
  end

  def current_subscription
    subscriptions.active.first || subscription
  end

  def current_plan
    return Plan.pro if on_trial? # Durante o trial, usuário tem acesso ao plano Pro
    current_subscription&.plan
  end

  def chosen_plan
    # Retorna o plano que o usuário escolheu, mesmo durante o trial
    current_subscription&.plan
  end

  def max_links_allowed
    # Para usuários em trial sem assinatura, limite de 5 links
    if on_trial? && !current_subscription
      return 5
    end

    current_plan_obj = current_plan
    return -1 if current_plan_obj&.max_links == -1 # Unlimited

    current_plan_obj&.max_links || 0
  end

  def can_create_links?
    return false unless active_subscription? || on_trial?

    max_allowed = max_links_allowed
    return true if max_allowed == -1 # Unlimited

    links.count < max_allowed
  end

  # Controle de acesso às funcionalidades avançadas
  def can_access_advanced_analytics?
    plan = current_plan
    return false unless plan
    ['Afiliado Pro', 'Afiliado Elite'].include?(plan.name)
  end

  def can_access_advanced_tracking?
    plan = current_plan
    return false unless plan
    ['Afiliado Pro', 'Afiliado Elite'].include?(plan.name)
  end

  def can_export_pdf?
    plan = current_plan
    return false unless plan
    ['Afiliado Pro', 'Afiliado Elite'].include?(plan.name)
  end

  def can_access_strategic_support?
    plan = current_plan
    return false unless plan
    plan.name == 'Afiliado Elite'
  end

  def has_basic_analytics_only?
    plan = current_plan
    return true unless plan
    plan.name == 'Afiliado Starter'
  end

  # Shopee Integration methods
  def has_shopee_integration?
    shopee_affiliate_integration&.connected?
  end

  def shopee_integration_active?
    shopee_affiliate_integration&.active?
  end

  def all_commissions_unified
    # Retorna todas as comissões (CSV + API) em um único conjunto
    commissions.includes(:user)
  end

  def api_commissions
    commissions.where(source: 'shopee_api')
  end

  def csv_commissions
    commissions.where(source: 'csv')
  end

  def total_api_commissions
    api_commissions.sum(:affiliate_commission) || 0
  end

  def total_csv_commissions
    csv_commissions.sum(:affiliate_commission) || 0
  end

  private

  def set_trial_period
    update(trial_ends_at: 14.days.from_now)
  end
end
