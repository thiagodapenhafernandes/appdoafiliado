class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  
  # Métodos de conveniência para acessar configurações
  def self.get(key, default = nil)
    setting = find_by(key: key.to_s)
    return default if setting.nil?
    
    # Tentar converter o valor para o tipo apropriado
    case setting.value
    when 'true', 'false'
      setting.value == 'true'
    when /^\d+$/
      setting.value.to_i
    when /^\d+\.\d+$/
      setting.value.to_f
    else
      setting.value
    end
  end
  
  def self.set(key, value, description = nil)
    setting = find_or_initialize_by(key: key.to_s)
    setting.value = value.to_s
    setting.description = description if description
    setting.save!
    setting
  end
  
  def self.payment_required?
    get('require_payment_on_signup', true)
  end
  
  def self.trial_days
    get('trial_days', 14)
  end
  
  def self.allow_simple_signup?
    get('allow_simple_signup', false)
  end
end
