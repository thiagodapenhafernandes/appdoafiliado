class Commission < ApplicationRecord
  # Deleta comissões por período para um usuário
  def self.delete_by_period(user, start_date, end_date)
    where(user_id: user.id, created_at: start_date.beginning_of_day..end_date.end_of_day).delete_all
  end

  # Deleta todas as comissões de um usuário
  def self.delete_all_for_user(user)
    where(user_id: user.id).delete_all
  end
  # Relationships
  belongs_to :user

  # Validations
  validates :order_id, presence: true
  validates :order_id, uniqueness: { scope: :user_id }

  # Scopes
  scope :by_channel, ->(channel) { where(channel: channel) }
  scope :by_date_range, ->(start_date, end_date) { where(order_date: start_date..end_date) }
  scope :completed, -> { where(order_status: 'completed') }
  scope :pending, -> { where(order_status: 'pending') }
  scope :cancelled, -> { where(order_status: 'cancelled') }
  scope :active, -> { where.not(order_status: 'cancelled') }
  
  # New scopes for data sources
  scope :from_api, -> { where(source: 'shopee_api') }
  scope :from_csv, -> { where(source: 'csv') }
  scope :with_external_id, -> { where.not(external_id: nil) }

  # Analytics scopes
  scope :by_category, ->(category) { where(category_l1: category) }
  scope :by_sub_id, ->(sub_id) { where(sub_id1: sub_id) }
  scope :by_store, ->(store_id) { where(store_id: store_id) }
  scope :this_month, -> { where(order_date: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :last_month, -> { where(order_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month) }

  # Methods
  def self.total_commissions
    sum(:commission_amount) || 0
  end

  def self.total_affiliate_commissions
    sum(:affiliate_commission) || 0
  end

  def self.total_sales
    sum(:sale_amount) || 0
  end

  def self.total_purchase_value
    sum(:purchase_value) || 0
  end

  def self.average_ticket
    return 0 if count.zero?
    total_purchase_value / count
  end

  def self.commission_rate
    return 0 if total_purchase_value.zero?
    (total_affiliate_commissions / total_purchase_value) * 100
  end

  def self.by_channel_summary
    group(:channel)
      .select('channel, COUNT(*) as orders_count, SUM(affiliate_commission) as total_commission, SUM(purchase_value) as total_sales')
      .order('total_commission DESC')
  end

  def self.monthly_evolution
    group_by_month(:order_date)
      .sum(:affiliate_commission)
  end

  def self.performance_metrics
    {
      total_orders: count,
      total_commission: total_affiliate_commissions,
      total_sales: total_purchase_value,
      average_commission: count > 0 ? total_affiliate_commissions / count : 0,
      average_ticket: average_ticket,
      commission_rate: commission_rate
    }
  end

  def self.top_categories(limit = 10)
    group(:category_l1)
      .select('category_l1, COUNT(*) as orders_count, SUM(affiliate_commission) as total_commission')
      .order('total_commission DESC')
      .limit(limit)
  end

  def self.top_products(limit = 10)
    group(:item_name)
      .select('item_name, COUNT(*) as orders_count, SUM(affiliate_commission) as total_commission, SUM(purchase_value) as total_sales')
      .order('total_commission DESC')
      .limit(limit)
  end

  def self.channel_performance
    group(:channel)
      .select('channel, 
               COUNT(*) as orders_count,
               SUM(affiliate_commission) as total_commission,
               SUM(purchase_value) as total_sales,
               AVG(affiliate_commission) as avg_commission,
               COUNT(CASE WHEN order_status = "completed" THEN 1 END) as completed_orders')
      .order('total_commission DESC')
  end

  def self.conversion_funnel
    total = count
    completed = completed.count
    pending = pending.count
    cancelled = cancelled.count
    
    {
      total: total,
      completed: completed,
      pending: pending,
      cancelled: cancelled,
      completion_rate: total > 0 ? (completed.to_f / total * 100).round(2) : 0,
      cancellation_rate: total > 0 ? (cancelled.to_f / total * 100).round(2) : 0
    }
  end

  # Instance methods
  def commission_percentage
    return 0 if purchase_value.nil? || purchase_value.zero?
    (affiliate_commission / purchase_value * 100).round(2)
  end

  def days_to_completion
    return nil unless completion_time && order_date
    (completion_time.to_date - order_date.to_date).to_i
  end

  def click_to_order_time
    return nil unless order_date && click_time
    ((order_date - click_time) / 1.hour).round(2) # Em horas
  end

  def profitable?
    affiliate_commission && affiliate_commission > 0
  end

  def status_color
    case order_status
    when 'completed'
      'green'
    when 'pending'
      'yellow'
    when 'cancelled'
      'red'
    else
      'gray'
    end
  end
end
