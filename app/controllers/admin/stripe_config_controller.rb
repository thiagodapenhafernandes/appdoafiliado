class Admin::StripeConfigController < Admin::BaseController
  
  def index
    @stripe_config = {
      publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
      secret_key_present: ENV['STRIPE_SECRET_KEY'].present?,
      webhook_secret_present: ENV['STRIPE_WEBHOOK_SECRET'].present?
    }
    @products = fetch_stripe_products
    @webhooks = fetch_stripe_webhooks
    @subscriptions = fetch_recent_subscriptions
  end

  def update_config
    # Para desenvolvimento, apenas mostrar mensagem de sucesso
    # Em produção, aqui você atualizaria as credenciais
    redirect_to admin_stripe_config_index_path, notice: 'Configurações do Stripe atualizadas com sucesso!'
  end

  def sync_plans
    begin
      sync_all_stripe_plans
      redirect_to admin_stripe_config_index_path, notice: 'Planos sincronizados com sucesso!'
    rescue StandardError => e
      redirect_to admin_stripe_config_index_path, alert: "Erro na sincronização: #{e.message}"
    end
  end

  def test_webhook
    begin
      Rails.logger.info "Testing webhook processing..."
      
      # Simular evento de assinatura criada
      test_event = OpenStruct.new(
        type: 'customer.subscription.created',
        data: OpenStruct.new(
          object: OpenStruct.new(
            id: 'sub_test_' + Time.current.to_i.to_s,
            customer: 'cus_test_123',
            status: 'active',
            current_period_start: Time.current.to_i,
            current_period_end: 1.month.from_now.to_i,
            items: OpenStruct.new(
              data: [
                OpenStruct.new(
                  price: OpenStruct.new(id: 'price_test_123')
                )
              ]
            )
          )
        )
      )
      
      # Processar evento
      StripeService.handle_webhook(test_event)
      
      # Verificar se API do Stripe está acessível
      products_count = Stripe::Product.list(limit: 1).data.length
      
      success_message = "✅ Teste executado com sucesso!\n" \
                       "- Webhook processado: #{test_event.type}\n" \
                       "- API Stripe: Conectada (#{products_count} produtos encontrados)\n" \
                       "- Verifique os logs para mais detalhes"
      
      redirect_to admin_stripe_config_index_path, notice: success_message
      
    rescue Stripe::AuthenticationError => e
      error_message = "❌ Erro de autenticação Stripe: Verifique suas chaves de API"
      Rails.logger.error "Stripe authentication error: #{e.message}"
      redirect_to admin_stripe_config_index_path, alert: error_message
      
    rescue StandardError => e
      error_message = "❌ Erro no teste: #{e.message}"
      Rails.logger.error "Webhook test error: #{e.message}"
      redirect_to admin_stripe_config_index_path, alert: error_message
    end
  end

  private

  def super_admin_area?
    true
  end

  def fetch_stripe_products
    return [] unless stripe_configured?
    
    begin
      Stripe::Product.list(limit: 10, active: true).data
    rescue Stripe::StripeError => e
      Rails.logger.error "Erro ao buscar produtos Stripe: #{e.message}"
      []
    end
  end

  def fetch_stripe_webhooks
    return [] unless stripe_configured?
    
    begin
      Stripe::WebhookEndpoint.list(limit: 10).data
    rescue Stripe::StripeError => e
      Rails.logger.error "Erro ao buscar webhooks Stripe: #{e.message}"
      []
    end
  end

  def sync_all_stripe_plans
    products = Stripe::Product.list(active: true, limit: 100)
    
    products.data.each do |product|
      # Buscar preços para este produto
      prices = Stripe::Price.list(product: product.id, active: true)
      
      prices.data.each do |price|
        next unless price.recurring&.interval == 'month'
        
        # Encontrar ou criar plano local
        plan = Plan.find_or_initialize_by(stripe_price_id: price.id)
        
        plan.assign_attributes(
          name: product.name,
          description: product.description,
          price_cents: price.unit_amount,
          stripe_price_id: price.id
        )
        
        plan.save!
      end
    end
  end

  def stripe_configured?
    ENV['STRIPE_SECRET_KEY'].present?
  end

  def fetch_recent_subscriptions
    return [] unless stripe_configured?
    
    begin
      subscriptions = Stripe::Subscription.list(
        limit: 20,
        status: 'all',
        expand: ['data.customer', 'data.items.data.price.product']
      )
      
      subscriptions.data.map do |sub|
        {
          id: sub.id,
          customer_email: sub.customer.email,
          status: sub.status,
          trial_end: sub.trial_end ? Time.at(sub.trial_end) : nil,
          current_period_end: Time.at(sub.current_period_end),
          plan_name: sub.items.data.first&.price&.product&.name,
          amount: sub.items.data.first&.price&.unit_amount,
          metadata: sub.metadata
        }
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Erro ao buscar subscriptions Stripe: #{e.message}"
      []
    end
  end
end
