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

    def create_subscription(user, plan)
      return unless stripe_configured? && plan.stripe_price_id.present?
      
      customer = ensure_customer(user)
      return unless customer

      begin
        subscription = Stripe::Subscription.create({
          customer: customer.id,
          items: [{ price: plan.stripe_price_id }],
          payment_behavior: 'default_incomplete',
          expand: ['latest_invoice.payment_intent'],
          metadata: { user_id: user.id, plan_id: plan.id }
        })

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

    def sync_user_subscriptions(user)
      return { success: false, error: 'Stripe não configurado' } unless stripe_configured?
      return { success: false, error: 'Usuário não possui Stripe Customer ID' } unless user.stripe_customer_id.present?

      begin
        # Buscar todas as assinaturas do cliente no Stripe
        stripe_subscriptions = Stripe::Subscription.list(
          customer: user.stripe_customer_id,
          status: 'all',
          limit: 100
        )

        synced_count = 0
        updated_count = 0

        stripe_subscriptions.data.each do |stripe_sub|
          # Buscar o plano local pelo price_id
          price_id = stripe_sub.items.data.first&.price&.id
          next unless price_id

          plan = Plan.find_by(stripe_price_id: price_id)
          next unless plan

          # Buscar ou criar assinatura local
          local_subscription = user.subscriptions.find_or_initialize_by(
            stripe_subscription_id: stripe_sub.id
          )

          if local_subscription.new_record?
            synced_count += 1
          else
            updated_count += 1
          end

          # Obter dados de período
          current_period_start = nil
          current_period_end = nil

          if stripe_sub.items&.data&.any?
            subscription_item = stripe_sub.items.data.first
            if subscription_item.respond_to?(:current_period_start)
              current_period_start = subscription_item.current_period_start
              current_period_end = subscription_item.current_period_end
            else
              current_period_start = stripe_sub.created
              current_period_end = stripe_sub.created + 30.days.to_i
            end
          else
            current_period_start = stripe_sub.created
            current_period_end = stripe_sub.created + 30.days.to_i
          end

          # Atualizar dados da assinatura local
          local_subscription.assign_attributes(
            plan: plan,
            status: stripe_sub.status,
            current_period_start: Time.at(current_period_start),
            current_period_end: Time.at(current_period_end),
            canceled_at: stripe_sub.canceled_at ? Time.at(stripe_sub.canceled_at) : nil
          )

          local_subscription.save!
        end

        {
          success: true,
          synced_count: synced_count,
          updated_count: updated_count,
          message: "#{synced_count} novas assinaturas sincronizadas, #{updated_count} assinaturas atualizadas"
        }

      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao sincronizar assinaturas do usuário #{user.id}: #{e.message}"
        { success: false, error: e.message }
      rescue StandardError => e
        Rails.logger.error "Erro inesperado ao sincronizar assinaturas: #{e.message}"
        { success: false, error: e.message }
      end
    end

    def sync_all_users_subscriptions
      return { success: false, error: 'Stripe não configurado' } unless stripe_configured?

      total_users = 0
      synced_users = 0
      errors = []

      User.where.not(stripe_customer_id: nil).find_each do |user|
        total_users += 1
        result = sync_user_subscriptions(user)

        if result[:success]
          synced_users += 1
        else
          errors << "Usuário #{user.email}: #{result[:error]}"
        end
      end

      {
        success: true,
        total_users: total_users,
        synced_users: synced_users,
        errors: errors,
        message: "#{synced_users}/#{total_users} usuários sincronizados com sucesso"
      }
    end

    def get_stripe_subscription_details(stripe_subscription_id)
      return nil unless stripe_configured?

      begin
        stripe_sub = Stripe::Subscription.retrieve(stripe_subscription_id, {
          expand: ['customer', 'items.data.price.product']
        })

        # Get period dates from subscription items if available
        current_period_start = nil
        current_period_end = nil

        if stripe_sub.items&.data&.any?
          subscription_item = stripe_sub.items.data.first
          if subscription_item.respond_to?(:current_period_start)
            current_period_start = subscription_item.current_period_start
            current_period_end = subscription_item.current_period_end
          else
            current_period_start = stripe_sub.created
            current_period_end = stripe_sub.created + 30.days.to_i
          end
        else
          current_period_start = stripe_sub.created
          current_period_end = stripe_sub.created + 30.days.to_i
        end

        {
          id: stripe_sub.id,
          status: stripe_sub.status,
          customer_email: stripe_sub.customer.email,
          plan_name: stripe_sub.items.data.first&.price&.product&.name || 'Produto não encontrado',
          amount: stripe_sub.items.data.first&.price&.unit_amount,
          current_period_start: current_period_start ? Time.at(current_period_start) : nil,
          current_period_end: current_period_end ? Time.at(current_period_end) : nil,
          canceled_at: stripe_sub.canceled_at ? Time.at(stripe_sub.canceled_at) : nil,
          trial_end: stripe_sub.trial_end ? Time.at(stripe_sub.trial_end) : nil
        }
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao buscar detalhes da assinatura: #{e.message}"
        nil
      end
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

        # Get period dates from subscription items if available
        if stripe_subscription.items&.data&.any?
          subscription_item = stripe_subscription.items.data.first
          if subscription_item.respond_to?(:current_period_start)
            subscription.current_period_start = Time.at(subscription_item.current_period_start)
            subscription.current_period_end = Time.at(subscription_item.current_period_end)
          else
            # Fallback to subscription created time and estimate period
            subscription.current_period_start = Time.at(stripe_subscription.created)
            subscription.current_period_end = Time.at(stripe_subscription.created) + 30.days
          end
        else
          subscription.current_period_start = Time.at(stripe_subscription.created)
          subscription.current_period_end = Time.at(stripe_subscription.created) + 30.days
        end
      end
    end

    def handle_subscription_updated(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      # Get period dates from subscription items if available
      current_period_start = nil
      current_period_end = nil

      if stripe_subscription.items&.data&.any?
        subscription_item = stripe_subscription.items.data.first
        if subscription_item.respond_to?(:current_period_start)
          current_period_start = subscription_item.current_period_start
          current_period_end = subscription_item.current_period_end
        else
          # Fallback to subscription created time and estimate period
          current_period_start = stripe_subscription.created
          current_period_end = stripe_subscription.created + 30.days.to_i
        end
      else
        current_period_start = stripe_subscription.created
        current_period_end = stripe_subscription.created + 30.days.to_i
      end

      subscription.update(
        status: stripe_subscription.status,
        current_period_start: Time.at(current_period_start),
        current_period_end: Time.at(current_period_end)
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
      # Access subscription ID from parent object based on Stripe API structure
      subscription_id = nil

      if invoice.respond_to?(:subscription) && invoice.subscription
        subscription_id = invoice.subscription
      elsif invoice.parent && invoice.parent.respond_to?(:subscription_details)
        subscription_id = invoice.parent.subscription_details.subscription
      end

      return unless subscription_id

      subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
      return unless subscription

      subscription.update(status: 'active')
    end

    def handle_payment_failed(invoice)
      # Access subscription ID from parent object based on Stripe API structure
      subscription_id = nil

      if invoice.respond_to?(:subscription) && invoice.subscription
        subscription_id = invoice.subscription
      elsif invoice.parent && invoice.parent.respond_to?(:subscription_details)
        subscription_id = invoice.parent.subscription_details.subscription
      end

      return unless subscription_id

      subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
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
