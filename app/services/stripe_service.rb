class StripeService
  class << self
    def create_customer(user)
      return unless stripe_configured?
      
      begin
        customer = Stripe::Customer.create({
          email: user.email,
          name: user.full_name,
          metadata: { user_id: user.id }
        })
        
        user.update(stripe_customer_id: customer.id)
        customer
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao criar cliente Stripe: #{e.message}"
        nil
      end
    end

    def create_subscription(user, plan, options = {})
      return unless stripe_configured? && plan.stripe_price_id.present?
      
      customer = ensure_customer(user)
      return unless customer

      begin
        subscription_params = {
          customer: customer.id,
          items: [{ price: plan.stripe_price_id }],
          payment_behavior: 'default_incomplete',
          expand: ['latest_invoice.payment_intent'],
          metadata: { user_id: user.id, plan_id: plan.id }
        }
        
        # Se skip_trial for true, não adicionar período de teste
        if options[:skip_trial]
          subscription_params[:trial_end] = 'now'
        end
        
        subscription = Stripe::Subscription.create(subscription_params)

        # Obter dados de período da subscription
        # Tentar diferentes formas de acessar os dados de período
        current_period_start = nil
        current_period_end = nil
        
        begin
          # Primeira tentativa: direto da subscription
          if subscription.respond_to?(:current_period_start)
            current_period_start = subscription.current_period_start
            current_period_end = subscription.current_period_end
          # Segunda tentativa: do primeiro item
          elsif subscription.items&.data&.any?
            subscription_item = subscription.items.data.first
            current_period_start = subscription_item.current_period_start
            current_period_end = subscription_item.current_period_end
          # Terceira tentativa: usar dados padrão
          else
            current_period_start = subscription.created
            current_period_end = subscription.created + 30.days.to_i
          end
        rescue => e
          Rails.logger.error "Erro ao obter período da subscription: #{e.message}"
          current_period_start = subscription.created
          current_period_end = subscription.created + 30.days.to_i
        end
        
        # Criar assinatura local
        local_subscription = user.subscriptions.create!(
          stripe_subscription_id: subscription.id,
          plan: plan,
          status: subscription.status,
          current_period_start: Time.at(current_period_start),
          current_period_end: Time.at(current_period_end)
        )

        # Obter client_secret para pagamento
        client_secret = nil
        if subscription.status == 'incomplete' && subscription.latest_invoice
          latest_invoice = subscription.latest_invoice
          
          # Se é uma string (ID), buscar a invoice completa
          if latest_invoice.is_a?(String)
            latest_invoice = Stripe::Invoice.retrieve(latest_invoice)
          end
          
          # Para invoices de subscription, sempre criar um novo payment_intent
          payment_intent = Stripe::PaymentIntent.create({
            amount: latest_invoice.amount_due,
            currency: latest_invoice.currency,
            customer: customer.id,
            automatic_payment_methods: {
              enabled: true,
            },
            metadata: {
              invoice_id: latest_invoice.id,
              subscription_id: subscription.id,
              plan_id: plan.id.to_s,
              user_id: user.id.to_s
            }
          })
          client_secret = payment_intent.client_secret
        end

        {
          subscription: subscription,
          local_subscription: local_subscription,
          client_secret: client_secret
        }
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao criar assinatura Stripe: #{e.message}"
        nil
      end
    end

    def create_subscription_with_token(user, plan, stripe_token, options = {})
      return unless stripe_configured? && plan.stripe_price_id.present?
      
      begin
        # Criar ou atualizar customer
        customer = ensure_customer(user)
        return unless customer

        # Criar source a partir do token
        source = Stripe::Source.create({
          type: 'card',
          token: stripe_token,
          currency: 'brl'
        })

        # Anexar source ao customer
        Stripe::Customer.update(customer.id, {
          source: source.id
        })

        # Criar subscription
        subscription_params = {
          customer: customer.id,
          items: [{ price: plan.stripe_price_id }],
          metadata: { user_id: user.id, plan_id: plan.id }
        }
        
        # Se skip_trial for true, não adicionar período de teste
        if options[:skip_trial]
          subscription_params[:trial_end] = 'now'
        else
          subscription_params[:trial_period_days] = 14
        end
        
        subscription = Stripe::Subscription.create(subscription_params)

        # Criar assinatura local
        local_subscription = user.subscriptions.create!(
          stripe_subscription_id: subscription.id,
          plan: plan,
          status: subscription.status,
          current_period_start: Time.at(subscription.current_period_start),
          current_period_end: Time.at(subscription.current_period_end)
        )

        {
          subscription: subscription,
          local_subscription: local_subscription,
          success: true
        }
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao criar assinatura com token: #{e.message}"
        { success: false, error: e.message }
      end
    end

    def cancel_subscription(subscription)
      return unless stripe_configured? && subscription.stripe_subscription_id.present?

      begin
        stripe_subscription = Stripe::Subscription.update(
          subscription.stripe_subscription_id,
          { cancel_at_period_end: true }
        )

        subscription.update(
          status: 'canceled',
          canceled_at: Time.current
        )

        stripe_subscription
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao cancelar assinatura Stripe: #{e.message}"
        nil
      end
    end

    def create_product_and_price(plan)
      return unless stripe_configured?

      begin
        # Criar produto
        product = Stripe::Product.create({
          name: plan.name,
          description: plan.description,
          metadata: { plan_id: plan.id }
        })

        # Criar preço
        price = Stripe::Price.create({
          product: product.id,
          unit_amount: plan.price_cents,
          currency: 'brl',
          recurring: { interval: 'month' },
          metadata: { plan_id: plan.id }
        })

        # Atualizar plano
        plan.update(
          stripe_product_id: product.id,
          stripe_price_id: price.id
        )

        { product: product, price: price }
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao criar produto/preço Stripe: #{e.message}"
        nil
      end
    end

    def sync_plans_from_stripe
      return unless stripe_configured?

      begin
        products = Stripe::Product.list(active: true, limit: 100)
        
        products.data.each do |product|
          prices = Stripe::Price.list(product: product.id, active: true)
          
          prices.data.each do |price|
            next unless price.recurring&.interval == 'month'
            
            plan = Plan.find_or_initialize_by(stripe_product_id: product.id)
            
            plan.assign_attributes(
              name: product.name,
              description: product.description,
              price_cents: price.unit_amount,
              stripe_price_id: price.id
            )
            
            plan.save!
          end
        end
        
        true
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao sincronizar planos: #{e.message}"
        false
      end
    end

    def handle_webhook(event)
      return unless stripe_configured?

      Rails.logger.info "Processing Stripe webhook: #{event.type}"

      case event.type
      when 'customer.subscription.created'
        handle_subscription_created(event.data.object)
      when 'customer.subscription.updated'
        handle_subscription_updated(event.data.object)
      when 'customer.subscription.deleted'
        handle_subscription_deleted(event.data.object)
      when 'customer.subscription.trial_will_end'
        handle_trial_will_end(event.data.object)
      when 'invoice.payment_succeeded'
        handle_payment_succeeded(event.data.object)
      when 'invoice.payment_failed'
        handle_payment_failed(event.data.object)
      when 'invoice.upcoming'
        handle_invoice_upcoming(event.data.object)
      when 'customer.updated'
        handle_customer_updated(event.data.object)
      when 'payment_method.attached'
        handle_payment_method_attached(event.data.object)
      else
        Rails.logger.info "Unhandled webhook event: #{event.type}"
      end
    rescue StandardError => e
      Rails.logger.error "Webhook processing error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end

    private

    def stripe_configured?
      ENV['STRIPE_SECRET_KEY'].present?
    end

    def ensure_customer(user)
      return nil unless stripe_configured?

      if user.stripe_customer_id.present?
        begin
          Stripe::Customer.retrieve(user.stripe_customer_id)
        rescue Stripe::StripeError
          create_customer(user)
        end
      else
        create_customer(user)
      end
    end

    def handle_subscription_created(stripe_subscription)
      user = User.find_by(stripe_customer_id: stripe_subscription.customer)
      return unless user

      plan = Plan.find_by(stripe_price_id: stripe_subscription.items.data.first.price.id)
      return unless plan

      user.subscriptions.find_or_create_by(stripe_subscription_id: stripe_subscription.id) do |subscription|
        subscription.plan = plan
        subscription.status = stripe_subscription.status
        subscription.current_period_start = Time.at(stripe_subscription.current_period_start)
        subscription.current_period_end = Time.at(stripe_subscription.current_period_end)
      end
    end

    def handle_subscription_updated(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      subscription.update(
        status: stripe_subscription.status,
        current_period_start: Time.at(stripe_subscription.current_period_start),
        current_period_end: Time.at(stripe_subscription.current_period_end)
      )
    end

    def handle_subscription_deleted(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      subscription.update(
        status: 'canceled',
        canceled_at: Time.current
      )
    end

    def handle_payment_succeeded(invoice)
      subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
      return unless subscription

      subscription.update(status: 'active')
    end

    def handle_payment_failed(invoice)
      subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
      return unless subscription

      subscription.update(status: 'past_due')
    end

    def handle_trial_will_end(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      # Notificar usuário sobre fim do trial
      Rails.logger.info "Trial ending for subscription #{subscription.id}"
      # TODO: Enviar email de notificação
    end

    def handle_invoice_upcoming(invoice)
      subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
      return unless subscription

      # Notificar usuário sobre cobrança próxima
      Rails.logger.info "Upcoming invoice for subscription #{subscription.id}"
      # TODO: Enviar email de lembrete
    end

    def handle_customer_updated(stripe_customer)
      user = User.find_by(stripe_customer_id: stripe_customer.id)
      return unless user

      # Atualizar dados do cliente se necessário
      Rails.logger.info "Customer updated: #{user.email}"
    end

    def handle_payment_method_attached(payment_method)
      user = User.find_by(stripe_customer_id: payment_method.customer)
      return unless user

      Rails.logger.info "Payment method attached for user: #{user.email}"
    end
  end
end
