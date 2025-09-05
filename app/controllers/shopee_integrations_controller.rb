class ShopeeIntegrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_integration, only: [:show, :edit, :update, :destroy, :test_connection, :sync_now, :toggle_status]

  def show
    @recent_conversions = current_user.affiliate_conversions
                                     .includes(:user)
                                     .order(conversion_time: :desc)
                                     .limit(10)
    
    @sync_stats = calculate_sync_stats
  end

  def new
    @integration = current_user.build_shopee_affiliate_integration
    @centralized_available = ShopeeAffiliateIntegration.centralized_available_for_market?('BR')
    @available_markets = available_markets_with_config
  end

  def create
    @integration = current_user.build_shopee_affiliate_integration(integration_params)
    
    if @integration.save
      # Test connection immediately after creation
      test_result = test_connection_async
      
      if test_result
        redirect_to shopee_integration_path, notice: 'Integração Shopee criada com sucesso! Conexão testada.'
      else
        redirect_to shopee_integration_path, alert: 'Integração criada, mas houve problema na conexão. Verifique as credenciais.'
      end
    else
      @centralized_available = ShopeeAffiliateIntegration.centralized_available_for_market?('BR')
      @available_markets = available_markets_with_config
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @integration.update(integration_params)
      # Test connection after updating credentials
      test_connection_async if credentials_changed?
      
      redirect_to shopee_integration_path, notice: 'Configurações atualizadas com sucesso!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @integration.destroy
    redirect_to analytics_path, notice: 'Integração Shopee removida com sucesso.'
  end

  def test_connection
    respond_to do |format|
      format.json do
        begin
          case @integration.auth_type
          when 'individual'
            client = ShopeeAffiliate::Client.new(@integration)
          when 'centralized', 'oauth'
            client = ShopeeAffiliate::CentralizedClient.new(@integration)
          end
          
          success = client.test_connection
          
          if success
            @integration.update!(last_error: nil)
            render json: { 
              success: true, 
              message: 'Conexão estabelecida com sucesso!',
              timestamp: Time.current.strftime('%d/%m/%Y %H:%M')
            }
          else
            error_msg = 'Falha na conexão. Verifique suas credenciais.'
            @integration.update!(last_error: error_msg)
            render json: { success: false, message: error_msg }
          end
        rescue => e
          error_msg = "Erro de conexão: #{e.message}"
          @integration.update!(last_error: error_msg)
          render json: { success: false, message: error_msg }
        end
      end
    end
  end

  def sync_now
    respond_to do |format|
      format.json do
        if @integration.active? && @integration.connected?
          # Schedule immediate sync
          ShopeeAffiliate::SyncConversionsJob.perform_later(@integration.id, { days_back: 7 })
          
          render json: { 
            success: true, 
            message: 'Sincronização agendada! Os dados serão atualizados em alguns minutos.',
            timestamp: Time.current.strftime('%d/%m/%Y %H:%M')
          }
        else
          render json: { 
            success: false, 
            message: 'Integração inativa ou credenciais inválidas.' 
          }
        end
      end
    end
  end

  def backfill
    respond_to do |format|
      format.json do
        days = params[:days]&.to_i || 30
        
        if @integration.active? && @integration.connected?
          ShopeeAffiliate::BackfillJob.perform_later(@integration.id, days)
          
          render json: { 
            success: true, 
            message: "Importação histórica de #{days} dias agendada! Este processo pode levar alguns minutos.",
            timestamp: Time.current.strftime('%d/%m/%Y %H:%M')
          }
        else
          render json: { 
            success: false, 
            message: 'Integração inativa ou credenciais inválidas.' 
          }
        end
      end
    end
  end

  def toggle_status
    respond_to do |format|
      format.json do
        @integration.update!(active: !@integration.active?)
        
        status_text = @integration.active? ? 'ativada' : 'desativada'
        render json: { 
          success: true, 
          message: "Integração #{status_text} com sucesso!",
          active: @integration.active?
        }
      end
    end
  end

  private

  def set_integration
    @integration = current_user.shopee_affiliate_integration
    
    unless @integration
      redirect_to new_shopee_integration_path, alert: 'Você precisa configurar a integração Shopee primeiro.'
    end
  end

  def integration_params
    params.require(:shopee_affiliate_integration).permit(
      :app_id, :secret, :market, :endpoint, :active, :auth_type,
      :shopee_user_id, :access_token, :refresh_token, :token_expires_at
    )
  end

  def credentials_changed?
    changed_keys = @integration.previous_changes.keys
    individual_creds = ['app_id', 'secret']
    centralized_creds = ['shopee_user_id', 'access_token', 'refresh_token']
    
    changed_keys.any? { |key| (individual_creds + centralized_creds).include?(key) }
  end

  def available_markets_with_config
    markets = [
      { code: 'BR', name: 'Brasil', endpoint: 'https://open-api.affiliate.shopee.com.br/graphql' },
      { code: 'MX', name: 'México', endpoint: 'https://open-api.affiliate.shopee.com.mx/graphql' },
      { code: 'CO', name: 'Colômbia', endpoint: 'https://open-api.affiliate.shopee.com.co/graphql' },
      { code: 'CL', name: 'Chile', endpoint: 'https://open-api.affiliate.shopee.cl/graphql' }
    ]
    
    markets.map do |market|
      market.merge(
        centralized_available: ShopeeAffiliateIntegration.centralized_available_for_market?(market[:code])
      )
    end
  end

  def test_connection_async
    ShopeeAffiliate::TestConnectionJob.perform_later(@integration.id)
    true
  rescue => e
    Rails.logger.error "Failed to schedule connection test: #{e.message}"
    false
  end

  def calculate_sync_stats
    return {} unless @integration

    {
      total_conversions: current_user.affiliate_conversions.count,
      api_commissions: current_user.api_commissions.sum(:affiliate_commission),
      last_sync: @integration.last_sync_at,
      sync_count: @integration.sync_count,
      has_error: @integration.last_error.present?,
      error_message: @integration.last_error,
      overdue: @integration.sync_overdue?
    }
  end
end
