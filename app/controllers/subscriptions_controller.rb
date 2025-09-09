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
    
    # Criar assinatura via Stripe (REAL, não simulação)
    # Verificar se deve pular o período de teste baseado no parâmetro
    skip_trial = params[:skip_trial] == 'true' || params[:subscription]&.[](:skip_trial) == 'true'
    stripe_result = StripeService.create_subscription(current_user, @plan, skip_trial: skip_trial)
    
    if stripe_result
      @subscription = stripe_result[:local_subscription]
      @client_secret = stripe_result[:client_secret]
      
      # Redirecionar para página de pagamento do Stripe
      redirect_to payment_subscription_path(@subscription, client_secret: @client_secret)
    else
      @subscription = current_user.subscriptions.build(plan: @plan)
      flash.now[:alert] = 'Erro ao processar assinatura. Tente novamente.'
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
