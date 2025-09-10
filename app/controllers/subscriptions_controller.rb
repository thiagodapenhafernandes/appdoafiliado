class SubscriptionsController < ApplicationController
  # Permitir acesso para new, create e show sem autenticação (com validações específicas)
  before_action :authenticate_user!, except: [:new, :create, :show]
  before_action :set_plan, only: [:new, :create]

  def new
    # Se usuário não estiver logado, mostrar formulário para criar conta + assinatura
    unless user_signed_in?
      @user = User.new
      @requires_registration = true
    end
    
    @subscription = (current_user&.subscriptions || Subscription).build(plan: @plan)
  end

  def create
    # Se usuário não estiver logado, criar conta primeiro
    if !user_signed_in? && params[:user].present?
      @user = create_user_from_params
      
      if @user.persisted?
        sign_in(@user)
      else
        @requires_registration = true
        @subscription = Subscription.new(plan: @plan)
        render :new, status: :unprocessable_entity
        return
      end
    elsif !user_signed_in?
      redirect_to new_user_registration_path, alert: 'Você precisa criar uma conta para continuar.'
      return
    end
    
    # Verificar se deve pular o período de teste baseado no parâmetro
    skip_trial = params[:skip_trial] == 'true' || params[:subscription]&.[](:skip_trial) == 'true'
    
    Rails.logger.info "=== SUBSCRIPTION CREATE DEBUG ==="
    Rails.logger.info "Plan price: #{@plan.price}"
    Rails.logger.info "Stripe token present: #{params[:stripe_token].present?}"
    Rails.logger.info "Stripe token value: #{params[:stripe_token]}"
    Rails.logger.info "Skip trial: #{skip_trial}"
    Rails.logger.info "User signed in: #{user_signed_in?}"
    Rails.logger.info "All params: #{params.inspect}"
    Rails.logger.info "================================="
    
    # Para planos gratuitos, criar assinatura simples
    if @plan.price == 0
      @subscription = current_user.subscriptions.create!(
        plan: @plan,
        status: 'active',
        current_period_start: Time.current,
        current_period_end: 1.month.from_now
      )
      redirect_to dashboard_path, notice: 'Assinatura criada com sucesso!'
      return
    end
    
    # Para planos pagos, verificar se token do Stripe foi fornecido
    if params[:stripe_token].blank?
      flash[:alert] = 'Dados do cartão são obrigatórios para planos pagos.'
      @requires_registration = !user_signed_in?
      @subscription = Subscription.new(plan: @plan)
      render :new, status: :unprocessable_entity
      return
    end
    
    # Criar assinatura via Stripe com token
    stripe_result = StripeService.create_subscription_with_token(
      current_user, 
      @plan, 
      params[:stripe_token],
      skip_trial: skip_trial
    )
    
    if stripe_result[:success]
      @subscription = stripe_result[:local_subscription]
      
      # Se é trial, redirecionar direto para dashboard
      if stripe_result[:local_subscription].status == 'trialing'
        redirect_to dashboard_path, notice: 'Período de teste iniciado com sucesso!'
      # Se precisa de pagamento confirmado, redirecionar para página de pagamento
      elsif stripe_result[:client_secret]
        redirect_to payment_subscription_path(@subscription, client_secret: stripe_result[:client_secret])
      # Se pagamento foi processado com sucesso
      else
        redirect_to dashboard_path, notice: 'Assinatura criada com sucesso!'
      end
    else
      @subscription = current_user.subscriptions.build(plan: @plan)
      @requires_registration = !user_signed_in?
      flash.now[:alert] = stripe_result[:error] || 'Erro ao processar assinatura. Tente novamente.'
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @subscription = Subscription.find(params[:id])
    
    # Verificar se o usuário tem permissão para ver essa subscription
    if user_signed_in?
      # Se logado, deve ser o dono da subscription
      unless @subscription.user == current_user
        redirect_to root_path, alert: 'Acesso negado.'
        return
      end
    else
      # Se não logado, redirecionar para login
      redirect_to new_user_session_path, alert: 'Você precisa estar logado para ver essa assinatura.'
      return
    end
  end

  # Nova action para página de pagamento
  def payment
    @subscription = current_user.subscriptions.find(params[:id])
    @client_secret = params[:client_secret]
    @plan = @subscription.plan
    
    redirect_to subscriptions_path, alert: 'Link de pagamento inválido.' unless @client_secret
  end

  private

  def set_plan
    plan_id = params[:plan_id] || params[:subscription]&.[](:plan_id)
    @plan = Plan.find(plan_id) if plan_id.present?
  end

  def create_user_from_params
    user_params = params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
    
    User.create(user_params.merge(
      role: :user
    ))
  end

  def subscription_params
    params.require(:subscription).permit(:plan_id)
  end
end
