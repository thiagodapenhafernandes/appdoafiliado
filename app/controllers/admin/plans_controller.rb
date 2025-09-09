class Admin::PlansController < Admin::BaseController
  before_action :set_plan, only: [:show, :edit, :update, :destroy, :sync_with_stripe]

  def index
    @plans = Plan.all.order(:price_cents)
  end

  def show
  end

  def new
    @plan = Plan.new
  end

  def create
    processed_params = plan_params
    # Processar features se for uma string com quebras de linha
    if processed_params[:features].is_a?(String) && processed_params[:features].include?("\n")
      processed_params[:features] = processed_params[:features].split("\n").map(&:strip).reject(&:blank?)
    end
    
    @plan = Plan.new(processed_params)
    
    if @plan.save
      # Criar produto e preço no Stripe
      create_stripe_product_and_price
      redirect_to admin_plan_path(@plan), notice: 'Plano criado com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    processed_params = plan_params
    # Processar features se for uma string com quebras de linha
    if processed_params[:features].is_a?(String) && processed_params[:features].include?("\n")
      processed_params[:features] = processed_params[:features].split("\n").map(&:strip).reject(&:blank?)
    end
    
    if @plan.update(processed_params)
      redirect_to admin_plan_path(@plan), notice: 'Plano atualizado com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @plan.subscriptions.exists?
      redirect_to admin_plans_path, alert: 'Não é possível excluir um plano que possui assinaturas ativas.'
    else
      @plan.destroy
      redirect_to admin_plans_path, notice: 'Plano excluído com sucesso!'
    end
  end

  def sync_with_stripe
    begin
      sync_plan_with_stripe(@plan)
      redirect_to admin_plan_path(@plan), notice: 'Plano sincronizado com o Stripe!'
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Erro de validação na sincronização: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      redirect_to admin_plan_path(@plan), alert: "Erro de validação: #{e.record.errors.full_messages.join(', ')}"
    rescue StandardError => e
      Rails.logger.error "Erro na sincronização: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      redirect_to admin_plan_path(@plan), alert: "Erro ao sincronizar: #{e.message}"
    end
  end

  def sync_from_stripe
    begin
      sync_plans_from_stripe
      redirect_to admin_plans_path, notice: 'Planos sincronizados do Stripe com sucesso!'
    rescue StandardError => e
      Rails.logger.error "Erro na sincronização do Stripe: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      redirect_to admin_plans_path, alert: "Erro ao sincronizar do Stripe: #{e.message}"
    end
  end

  private

  def set_plan
    @plan = Plan.find(params[:id])
  end

  def plan_params
    params.require(:plan).permit(:name, :description, :price_cents, :stripe_price_id, :features, :max_links, :popular, :active)
  end

  def create_stripe_product_and_price
    return unless Rails.env.production? || @plan.stripe_price_id.blank?

    begin
      # Criar produto no Stripe
      product = Stripe::Product.create({
        name: @plan.name,
        description: @plan.description,
        metadata: { plan_id: @plan.id }
      })

      # Criar preço no Stripe
      price = Stripe::Price.create({
        product: product.id,
        unit_amount: @plan.price_cents,
        currency: 'brl',
        recurring: {
          interval: 'month'
        },
        metadata: { plan_id: @plan.id }
      })

      # Atualizar o plano apenas com o Price ID (usando update_column para pular validações)
      @plan.update_column(:stripe_price_id, price.id)
    rescue Stripe::StripeError => e
      Rails.logger.error "Erro ao criar produto/preço no Stripe: #{e.message}"
    end
  end

  def sync_plan_with_stripe(plan)
    # Se já está sincronizado, apenas validar
    if plan.stripe_price_id.present?
      begin
        stripe_price = Stripe::Price.retrieve(plan.stripe_price_id)
        Rails.logger.info "Plano #{plan.name} já sincronizado com Price ID: #{stripe_price.id}"
        return true
      rescue Stripe::StripeError => e
        Rails.logger.error "Erro ao validar Price ID no Stripe: #{e.message}"
        # Se o Price ID não existe mais no Stripe, remover e recriar
        plan.update_column(:stripe_price_id, nil) # Usa update_column para pular validações
      end
    end

    # Criar novo produto e preço no Stripe
    begin
      Rails.logger.info "Criando novo produto/preço no Stripe para: #{plan.name}"
      
      # Criar produto no Stripe
      product = Stripe::Product.create({
        name: plan.name,
        description: plan.description,
        metadata: { plan_id: plan.id }
      })

      # Criar preço no Stripe
      price = Stripe::Price.create({
        product: product.id,
        unit_amount: plan.price_cents,
        currency: 'brl',
        recurring: {
          interval: 'month'
        },
        metadata: { plan_id: plan.id }
      })

      # Atualizar o plano com o Price ID (usando update_column para pular validações)
      plan.update_column(:stripe_price_id, price.id)
      Rails.logger.info "Plano #{plan.name} sincronizado com sucesso! Price ID: #{price.id}"
      
      return true
    rescue Stripe::StripeError => e
      Rails.logger.error "Erro ao criar produto/preço no Stripe: #{e.message}"
      raise e
    end
  end

  def sync_plans_from_stripe
    Rails.logger.info "Iniciando sincronização de planos do Stripe..."
    
    # Buscar todos os produtos ativos no Stripe
    products = Stripe::Product.list(active: true, limit: 100)
    
    products.data.each do |stripe_product|
      # Buscar preços para este produto
      prices = Stripe::Price.list(product: stripe_product.id, active: true)
      
      prices.data.each do |stripe_price|
        next unless stripe_price.recurring&.interval == 'month' && stripe_price.currency == 'brl'
        
        # Verificar se já existe um plano com este price_id
        existing_plan = Plan.find_by(stripe_price_id: stripe_price.id)
        
        if existing_plan
          # Atualizar plano existente com dados do Stripe
          Rails.logger.info "Atualizando plano existente: #{existing_plan.name}"
          existing_plan.sync_from_stripe!(
            name: stripe_product.name,
            description: stripe_product.description,
            price_cents: stripe_price.unit_amount
          )
        else
          # Verificar se existe plano com mesmo nome (para evitar duplicação)
          existing_by_name = Plan.find_by(name: stripe_product.name)
          
          if existing_by_name && existing_by_name.stripe_price_id.blank?
            # Atualizar plano existente sem stripe_price_id
            Rails.logger.info "Vinculando plano existente ao Stripe: #{existing_by_name.name}"
            existing_by_name.update_column(:stripe_price_id, stripe_price.id)
            existing_by_name.sync_from_stripe!(
              price_cents: stripe_price.unit_amount,
              description: stripe_product.description
            )
          else
            # Criar novo plano
            Rails.logger.info "Criando novo plano do Stripe: #{stripe_product.name}"
            plan = Plan.new(
              name: stripe_product.name,
              description: stripe_product.description,
              price_cents: stripe_price.unit_amount,
              stripe_price_id: stripe_price.id,
              active: true
            )
            plan.syncing_from_stripe = true
            plan.save!
          end
        end
      end
    end
    
    Rails.logger.info "Sincronização de planos do Stripe concluída!"
  end
end
