class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :load_plans, only: [:new, :create]

  # GET /resource/sign_up
  def new
    build_resource({})
    @selected_plan = params[:plan].present? ? Plan.find_by(id: params[:plan]) : Plan.pro
    @selected_plan ||= Plan.pro # fallback to Pro plan
    @simple_signup = params[:simple] == 'true'
    yield resource if block_given?
    respond_with resource
  end

  # POST /resource
  def create
    @selected_plan = Plan.find_by(id: params[:plan_id]) || Plan.pro
    
    build_resource(sign_up_params)
    
    # Validar se todos os campos necessários estão presentes
    unless resource.valid?
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
      return
    end
    
    # Verificar se pagamento é obrigatório (configurável)
    payment_required = Setting.payment_required?
    simple_signup_allowed = Setting.allow_simple_signup?
    stripe_unavailable = params[:stripe_unavailable] == 'true'
    
    # Se Stripe não estiver disponível em produção, permitir cadastro simples temporariamente
    if stripe_unavailable && payment_required
      Rails.logger.warn "Stripe unavailable for user #{resource.email}, allowing temporary simple signup"
      simple_signup_allowed = true
      payment_required = false
    end
    
    if payment_required && params[:payment_method_id].blank? && !simple_signup_allowed
      resource.errors.add(:base, I18n.t('registrations.payment_method_required'))
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
      return
    end
    
    resource.save
    yield resource if block_given?
    
    if resource.persisted?
      if resource.active_for_authentication?
        # Verificar se deve usar Stripe ou cadastro simples
        if params[:payment_method_id].present? && payment_required
          # Usar Stripe
          Rails.logger.info "Creating Stripe subscription for user #{resource.email}"
          begin
            payment_method_id = params[:payment_method_id]
            create_stripe_subscription_with_trial(resource, @selected_plan, payment_method_id)
            set_flash_message! :notice, :signed_up_with_stripe_trial, trial_days: Setting.trial_days
            sign_up(resource_name, resource)
            respond_with resource, location: after_sign_up_path_for(resource)
          rescue Stripe::CardError => e
            # Handle card errors - mais específico
            Rails.logger.error "Stripe card error for #{resource.email}: #{e.message}"
            resource.destroy
            case e.code
            when 'card_declined'
            flash[:alert] = I18n.t('stripe_errors.card_declined')
            when 'expired_card'
              flash[:alert] = I18n.t('stripe_errors.expired_card')
            when 'incorrect_cvc'
              flash[:alert] = I18n.t('stripe_errors.incorrect_cvc')
            when 'insufficient_funds'
              flash[:alert] = I18n.t('stripe_errors.insufficient_funds')
            else
              flash[:alert] = I18n.t('stripe_errors.generic_error')
            end
            redirect_to new_user_registration_path(plan: @selected_plan.id)
          rescue Stripe::RateLimitError => e
            Rails.logger.error "Stripe rate limit for #{resource.email}: #{e.message}"
            resource.destroy
            flash[:alert] = I18n.t('stripe_errors.rate_limit')
            redirect_to new_user_registration_path(plan: @selected_plan.id)
          rescue Stripe::InvalidRequestError => e
            Rails.logger.error "Stripe invalid request for #{resource.email}: #{e.message}"
            resource.destroy
            flash[:alert] = I18n.t('stripe_errors.invalid_request')
            redirect_to new_user_registration_path(plan: @selected_plan.id)
          rescue Stripe::AuthenticationError => e
            Rails.logger.error "Stripe auth error for #{resource.email}: #{e.message}"
            resource.destroy
            flash[:alert] = I18n.t('stripe_errors.authentication_error')
            redirect_to new_user_registration_path(plan: @selected_plan.id)
          rescue Stripe::APIConnectionError => e
            Rails.logger.error "Stripe connection error for #{resource.email}: #{e.message}"
            resource.destroy
            if simple_signup_allowed
              flash[:alert] = I18n.t('stripe_errors.connection_error_simple')
              redirect_to new_user_registration_path(plan: @selected_plan.id, simple: true)
            else
              flash[:alert] = I18n.t('stripe_errors.connection_error')
              redirect_to new_user_registration_path(plan: @selected_plan.id)
            end
          rescue Stripe::StripeError => e
            # Handle other Stripe errors
            Rails.logger.error "Generic Stripe error for #{resource.email}: #{e.message}"
            resource.destroy
            flash[:alert] = I18n.t('stripe_errors.generic_error')
            redirect_to new_user_registration_path(plan: @selected_plan.id)
          rescue => e
            # Handle any other errors
            Rails.logger.error "Unexpected error during registration for #{resource.email}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            resource.destroy
            if simple_signup_allowed
              flash[:alert] = I18n.t('stripe_errors.unexpected_error_simple')
              redirect_to new_user_registration_path(plan: @selected_plan.id, simple: true)
            else
              flash[:alert] = I18n.t('stripe_errors.unexpected_error')
              redirect_to new_user_registration_path(plan: @selected_plan.id)
            end
          end
        elsif simple_signup_allowed || !payment_required
          # Cadastro simples permitido
          Rails.logger.info "Creating simple signup for user #{resource.email}"
          trial_days = Setting.trial_days
          resource.update!(trial_ends_at: trial_days.days.from_now)
          
          if stripe_unavailable
            # Marcar usuário para configurar pagamento depois
            resource.update!(stripe_setup_needed: true)
            set_flash_message! :notice, :signed_up_with_stripe_unavailable, trial_days: trial_days
          else
            set_flash_message! :notice, :signed_up_with_trial, trial_days: trial_days
          end
          
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          # Nenhuma opção válida
          resource.destroy
          flash[:alert] = I18n.t('registrations.payment_method_required_to_create')
          redirect_to new_user_registration_path(plan: @selected_plan.id)
        end
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone])
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  private

  def load_plans
    @plans = Plan.active.order(:price_cents)
  end

  private

  def create_stripe_subscription_with_trial(user, plan, payment_method_id)
    Rails.logger.info "Creating Stripe subscription for user #{user.id} with plan #{plan.name}"

    # Check if Stripe is properly configured
    unless plan.stripe_price_id.present? && plan.stripe_price_id != 'price_starter_placeholder' && 
           plan.stripe_price_id != 'price_pro_placeholder' && plan.stripe_price_id != 'price_elite_placeholder'
      Rails.logger.warn "Plan #{plan.name} has invalid Stripe price ID: #{plan.stripe_price_id}"
      raise Stripe::InvalidRequestError.new("Plan not properly configured for Stripe", "stripe_price_id")
    end

    # Create Stripe customer
    stripe_customer = Stripe::Customer.create(
      email: user.email,
      name: "#{user.first_name} #{user.last_name}"
    )

    # Attach payment method to customer if provided
    if payment_method_id.present?
      Stripe::PaymentMethod.attach(payment_method_id, customer: stripe_customer.id)
      
      # Set as default payment method
      Stripe::Customer.update(
        stripe_customer.id,
        invoice_settings: { default_payment_method: payment_method_id }
      )
    end

    # Create subscription with 14-day trial
    stripe_subscription = Stripe::Subscription.create(
      customer: stripe_customer.id,
      items: [{ price: plan.stripe_price_id }],
      trial_period_days: 14,
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
      metadata: {
        user_id: user.id,
        plan_id: plan.id,
        environment: Rails.env
      }
    )

    # Update user with Stripe customer ID
    user.update!(
      stripe_customer_id: stripe_customer.id,
      trial_ends_at: 14.days.from_now
    )

    # Create subscription record
    subscription = user.subscriptions.create!(
      plan: plan,
      status: 'trialing',
      stripe_subscription_id: stripe_subscription.id,
      current_period_start: Time.at(stripe_subscription.current_period_start),
      current_period_end: Time.at(stripe_subscription.current_period_end),
      trial_ends_at: 14.days.from_now,
      stripe_customer_id: stripe_customer.id
    )

    # Set as user's active subscription
    user.update!(subscription: subscription)

    subscription
  end
end
