class Device < ApplicationRecord
  # Relationships
  belongs_to :user

  # Validations
  validates :device_id, presence: true, uniqueness: true
  
  # Scopes
  scope :trusted, -> { where(trusted: true) }
  scope :recent, -> { where('last_seen_at > ?', 30.days.ago) }

  # Methods
  def mark_as_trusted!
    update!(trusted: true)
  end

  def update_last_seen!
    update!(last_seen_at: Time.current)
  end

  def device_name
    "#{browser} on #{os}"
  end

  def self.create_from_request(user, request)
    device_id = generate_device_id(request)
    
    find_or_create_by(device_id: device_id) do |device|
      device.user = user
      device.device_type = detect_device_type(request.user_agent)
      device.browser = detect_browser(request.user_agent)
      device.os = detect_os(request.user_agent)
      device.ip_address = request.remote_ip
      device.user_agent = request.user_agent
      device.last_seen_at = Time.current
    end
  end

  private

  def self.generate_device_id(request)
    # Simple device fingerprinting based on user agent and IP
    Digest::SHA256.hexdigest("#{request.user_agent}#{request.remote_ip}")[0..15]
  end

  def self.detect_device_type(user_agent)
    case user_agent
    when /Mobile|Android|iPhone|iPad/
      'mobile'
    when /Tablet|iPad/
      'tablet'
    else
      'desktop'
    end
  end

  def self.detect_browser(user_agent)
    case user_agent
    when /Chrome/
      'Chrome'
    when /Firefox/
      'Firefox'
    when /Safari/
      'Safari'
    when /Edge/
      'Edge'
    else
      'Unknown'
    end
  end

  def self.detect_os(user_agent)
    case user_agent
    when /Windows/
      'Windows'
    when /Mac OS X|macOS/
      'macOS'
    when /Linux/
      'Linux'
    when /Android/
      'Android'
    when /iPhone|iPad/
      'iOS'
    else
      'Unknown'
    end
  end
end
