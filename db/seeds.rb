# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Super Admin User
puts "Creating super admin user..."

super_admin = User.find_or_create_by(email: 'admin@unitymob.com.br') do |user|
  user.first_name = 'Super'
  user.last_name = 'Admin'
  user.password = 'admin123'
  user.password_confirmation = 'admin123'
  user.role = 'super_admin'
end

puts "Super Admin created: #{super_admin.email} (Password: admin123)"

puts "Configuring single plan..."

default_plan = Plan.find_or_initialize_by(name: Plan::DEFAULT_PLAN_NAME)
default_plan.description = "Acesso completo ao LinkFlow com todos os recursos liberados."
default_plan.price_cents = 4700 # R$ 47,00
default_plan.currency = 'BRL'
default_plan.max_links = -1 # Ilimitado
default_plan.popular = true
default_plan.features = [
  "Links ilimitados",
  "Analytics avançado em tempo real",
  "Importação de cliques e comissões via CSV",
  "Rastreamento avançado com SubIDs",
  "Exportação de relatórios em PDF",
  "Suporte estratégico prioritário"
]
default_plan.active = true
default_plan.save!

puts "✅ Plano '#{default_plan.name}' configurado (#{default_plan.price_formatted}/mês)"

# Create default settings
puts "\nCreating default settings..."

default_settings = [
  {
    key: 'require_payment_on_signup',
    value: 'true',
    description: 'Exigir pagamento obrigatório no cadastro'
  },
  {
    key: 'allow_simple_signup',
    value: 'false',
    description: 'Permitir cadastro simples sem pagamento (apenas se require_payment_on_signup for false)'
  },
  {
    key: 'trial_days',
    value: '14',
    description: 'Número de dias de trial gratuito para novos usuários'
  },
  {
    key: 'stripe_webhook_enabled',
    value: 'true',
    description: 'Habilitar processamento de webhooks do Stripe'
  },
  {
    key: 'max_links_per_user',
    value: '100',
    description: 'Número máximo de links por usuário (para planos ilimitados)'
  },
  {
    key: 'system_maintenance_mode',
    value: 'false',
    description: 'Ativar modo de manutenção do sistema'
  }
]

default_settings.each do |setting_data|
  setting = Setting.find_or_create_by(key: setting_data[:key]) do |s|
    s.value = setting_data[:value]
    s.description = setting_data[:description]
  end
  
  puts "✅ Setting '#{setting.key}' = '#{setting.value}'"
end

# Create full access user account
puts "\nCreating full access account..."

full_access_user = User.find_or_initialize_by(email: 'conta@appdoafiliado.com')
full_access_user.first_name = 'Conta'
full_access_user.last_name = 'Completa'
full_access_user.password = 'linkflow123'
full_access_user.password_confirmation = 'linkflow123'
full_access_user.role ||= 'user'
full_access_user.save!

subscription = full_access_user.subscriptions.find_or_initialize_by(plan: default_plan)
subscription.status ||= 'active'
subscription.current_period_start ||= Time.current
subscription.current_period_end ||= 30.days.from_now
subscription.trial_ends_at = nil
subscription.save!

if full_access_user.subscription_id != subscription.id
  full_access_user.update(subscription: subscription)
end

puts "✅ Conta completa disponível: #{full_access_user.email} (senha: linkflow123)"
puts "Seeds completed!"
