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

# Create Plans
puts "Creating plans..."

plans_data = [
  {
    name: "Afiliado Starter",
    description: "Para iniciantes",
    price_cents: 5990, # R$ 59,90
    stripe_price_id: ENV['STRIPE_STARTER_PRICE_ID'] || 'price_starter_placeholder',
    max_links: 15,
    popular: false,
    features: [
      "15 links de redirecionamento",
      "Análise de comissões e cliques na Shopee",
      "Estatísticas básicas",
      "Rastreamento básico",
      "Suporte via WhatsApp"
    ]
  },
  {
    name: "Afiliado Pro",
    description: "Mais popular",
    price_cents: 9790, # R$ 97,90
    stripe_price_id: ENV['STRIPE_PRO_PRICE_ID'] || 'price_pro_placeholder',
    max_links: 50,
    popular: true,
    features: [
      "50 links de redirecionamento",
      "Análise de comissões e cliques na Shopee",
      "Estatísticas avançadas",
      "Rastreamento avançado",
      "Suporte via WhatsApp"
    ]
  },
  {
    name: "Afiliado Elite",
    description: "Para Experts",
    price_cents: 14790, # R$ 147,90
    stripe_price_id: ENV['STRIPE_ELITE_PRICE_ID'] || 'price_elite_placeholder',
    max_links: -1, # Ilimitado
    popular: false,
    features: [
      "Links ilimitados",
      "Análise de comissões e cliques na Shopee",
      "Estatísticas avançadas",
      "Rastreamento avançado",
      "Suporte via WhatsApp",
      "Suporte estratégico"
    ]
  }
]

plans_data.each do |plan_data|
  plan = Plan.find_or_create_by(name: plan_data[:name]) do |p|
    p.description = plan_data[:description]
    p.price_cents = plan_data[:price_cents]
    p.currency = 'BRL'
    p.stripe_price_id = plan_data[:stripe_price_id]
    p.max_links = plan_data[:max_links]
    p.popular = plan_data[:popular]
    p.features = plan_data[:features]
    p.active = true
  end
  
  # Update existing plans with stripe_price_id if missing
  if plan.stripe_price_id.blank?
    plan.update!(stripe_price_id: plan_data[:stripe_price_id])
  end
  
  puts "✅ Plan '#{plan.name}' created/updated"
end

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

puts "Seeds completed!"
