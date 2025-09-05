# app/models/shopee_api_request.rb
class ShopeeApiRequest < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :shopee_master_config

  validates :endpoint, presence: true
  validates :method, presence: true, inclusion: { in: %w[GET POST PUT DELETE] }
  validates :status_code, presence: true, numericality: { greater_than: 0 }

  scope :successful, -> { where(status_code: 200..299) }
  scope :failed, -> { where.not(status_code: 200..299) }
  scope :recent, -> { where(created_at: 24.hours.ago..Time.current) }

  # Class methods para rate limiting
  def self.log_request(user: nil, config:, endpoint:, method:, status_code:, response_time: nil, error: nil)
    create!(
      user: user,
      shopee_master_config: config,
      endpoint: endpoint,
      method: method,
      status_code: status_code,
      response_time_ms: response_time,
      error_message: error&.message
    )
  end

  def self.requests_in_last_minute
    where(created_at: 1.minute.ago..Time.current).count
  end

  def self.requests_in_last_hour
    where(created_at: 1.hour.ago..Time.current).count
  end

  def successful?
    status_code.between?(200, 299)
  end
end
