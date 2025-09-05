# app/controllers/admin/shopee_config_controller.rb
class Admin::ShopeeConfigsController < Admin::BaseController
  before_action :require_super_admin
  before_action :set_config, only: [:show, :edit, :update, :test_connection, :toggle_status]

  def index
    @configs = ShopeeMasterConfig.all.order(:market)
    @brazil_config = ShopeeMasterConfig.find_by(market: 'BR')
    
    # Estatísticas de uso da API
    @api_stats = {
      requests_today: ShopeeApiRequest.where(created_at: Date.current.all_day).count,
      requests_last_hour: ShopeeApiRequest.requests_in_last_hour,
      requests_last_minute: ShopeeApiRequest.requests_in_last_minute,
      success_rate: calculate_success_rate,
      active_users: active_users_count
    }
  end

  def show
    @recent_requests = @config.shopee_api_requests.recent.limit(50).order(created_at: :desc)
    @usage_stats = calculate_usage_stats(@config)
  end

  def new
    @config = ShopeeMasterConfig.new
  end

  def create
    @config = ShopeeMasterConfig.new(config_params)
    
    if @config.save
      redirect_to admin_shopee_config_index_path, 
                  notice: 'Configuração Shopee criada com sucesso!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @config.update(config_params)
      redirect_to admin_shopee_config_path(@config), 
                  notice: 'Configuração atualizada com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def test_connection
    respond_to do |format|
      if @config.test_connection
        @config.update!(
          last_tested_at: Time.current,
          last_test_result: 'Conexão bem-sucedida!'
        )
        
        format.json { render json: { success: true, message: 'Conexão testada com sucesso!' } }
        format.html { redirect_to admin_shopee_config_path(@config), notice: 'Conexão testada com sucesso!' }
      else
        @config.update!(
          last_tested_at: Time.current,
          last_test_result: 'Falha na conexão - verifique as credenciais'
        )
        
        format.json { render json: { success: false, message: 'Falha na conexão - verifique as credenciais' } }
        format.html { redirect_to admin_shopee_config_path(@config), alert: 'Falha na conexão - verifique as credenciais' }
      end
    end
  end

  def toggle_status
    @config.update!(active: !@config.active?)
    
    status = @config.active? ? 'ativada' : 'desativada'
    redirect_to admin_shopee_config_path(@config), 
                notice: "Configuração #{status} com sucesso!"
  end

  def destroy
    @config = ShopeeMasterConfig.find(params[:id])
    
    if @config.shopee_api_requests.exists?
      redirect_to admin_shopee_config_index_path, 
                  alert: 'Não é possível remover configuração com histórico de requests.'
    else
      @config.destroy!
      redirect_to admin_shopee_config_index_path, 
                  notice: 'Configuração removida com sucesso!'
    end
  end

  private

  def set_config
    @config = ShopeeMasterConfig.find(params[:id])
  end

  def config_params
    params.require(:shopee_master_config).permit(
      :market, :endpoint, :master_app_id, :master_secret, :active,
      :rate_limit_per_minute, :rate_limit_per_hour, :notes
    )
  end

  def require_super_admin
    unless current_user&.super_admin?
      redirect_to admin_dashboard_index_path, 
                  alert: 'Acesso negado. Apenas super admins podem configurar integrações Shopee.'
    end
  end

  def calculate_success_rate
    total = ShopeeApiRequest.where(created_at: 24.hours.ago..Time.current).count
    return 0 if total.zero?
    
    successful = ShopeeApiRequest.successful.where(created_at: 24.hours.ago..Time.current).count
    (successful.to_f / total * 100).round(2)
  end

  def active_users_count
    ShopeeAffiliateIntegration.joins(:user)
                             .where(active: true, auth_type: 'centralized')
                             .count
  end

  def calculate_usage_stats(config)
    {
      total_requests: config.shopee_api_requests.count,
      requests_today: config.shopee_api_requests.where(created_at: Date.current.all_day).count,
      success_rate: calculate_config_success_rate(config),
      average_response_time: config.shopee_api_requests.where.not(response_time_ms: nil).average(:response_time_ms)&.round(2),
      users_count: ShopeeAffiliateIntegration.where(auth_type: 'centralized').count
    }
  end

  def calculate_config_success_rate(config)
    total = config.shopee_api_requests.where(created_at: 24.hours.ago..Time.current).count
    return 0 if total.zero?
    
    successful = config.shopee_api_requests.successful.where(created_at: 24.hours.ago..Time.current).count
    (successful.to_f / total * 100).round(2)
  end
end
