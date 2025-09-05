class AffiliateConversion < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :shopee_affiliate_integration, optional: true

  # Validations
  validates :external_id, presence: true, uniqueness: { scope: :user_id }
  validates :source, inclusion: { in: %w[shopee_api csv manual] }
  validates :currency, inclusion: { in: %w[BRL USD SGD MYR THB VND PHP TWD] }
  validates :commission_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0 }

  # Scopes
  scope :from_api, -> { where(source: 'shopee_api') }
  scope :from_csv, -> { where(source: 'csv') }
  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :by_date_range, ->(start_date, end_date) { where(conversion_time: start_date..end_date) }
  scope :by_sub_id, ->(sub_id) { where(sub_id: sub_id) }
  scope :recent, -> { order(conversion_time: :desc) }

  # Callbacks
  before_validation :set_defaults
  after_create :sync_to_commission, if: :should_sync_to_commission?

  # Instance methods
  def commission_amount
    commission_cents / 100.0 if commission_cents.present?
  end

  def commission_amount=(value)
    self.commission_cents = (value.to_f * 100).to_i if value.present?
  end

  def completed?
    status == 'completed'
  end

  def from_api?
    source == 'shopee_api'
  end

  def from_csv?
    source == 'csv'
  end

  # Convert to Commission format for unified reporting
  def to_commission_attributes
    {
      user_id: user_id,
      order_id: order_id,
      external_id: external_id,
      source: source,
      channel: channel || 'Shopee',
      commission_amount: commission_amount,
      sale_amount: purchase_value,
      order_status: status == 'completed' ? 'completed' : 'pending',
      commission_type: 'shopee',
      product_name: extract_product_name,
      category: category,
      order_date: conversion_time,
      commission_date: conversion_time,
      item_id: item_id,
      item_name: extract_product_name,
      quantity: quantity,
      purchase_value: purchase_value,
      affiliate_commission: commission_amount,
      affiliate_status: status&.capitalize,
      sub_id1: sub_id
    }
  end

  private

  def set_defaults
    self.currency ||= 'BRL'
    self.quantity ||= 1
    self.commission_cents ||= 0
    self.source ||= 'shopee_api'
    self.status ||= 'pending'
  end

  def should_sync_to_commission?
    # Sync to main commissions table if it's from API and completed
    from_api? && completed?
  end

  def sync_to_commission
    # Avoid duplicate commissions
    return if Commission.exists?(external_id: external_id, user_id: user_id)

    Commission.create!(to_commission_attributes)
  rescue => e
    Rails.logger.error "Failed to sync affiliate conversion #{id} to commission: #{e.message}"
  end

  def extract_product_name
    return raw_data&.dig('product_name') if raw_data.present?
    return raw_data&.dig('item_name') if raw_data.present?
    "Product #{item_id}"
  end
end
