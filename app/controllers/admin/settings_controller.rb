class Admin::SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  
  def index
    @settings = Setting.all.order(:key)
    @new_setting = Setting.new
  end
  
  def update
    @setting = Setting.find(params[:id])
    
    if @setting.update(setting_params)
      redirect_to admin_settings_path, notice: 'Configuração atualizada com sucesso.'
    else
      redirect_to admin_settings_path, alert: 'Erro ao atualizar configuração.'
    end
  end
  
  def create
    @setting = Setting.new(setting_params)
    
    if @setting.save
      redirect_to admin_settings_path, notice: 'Configuração criada com sucesso.'
    else
      redirect_to admin_settings_path, alert: 'Erro ao criar configuração.'
    end
  end
  
  def destroy
    @setting = Setting.find(params[:id])
    @setting.destroy
    redirect_to admin_settings_path, notice: 'Configuração removida com sucesso.'
  end
  
  def reset_defaults
    # Configurações padrão
    Setting.set('require_payment_on_signup', true, 'Exigir pagamento obrigatório no cadastro')
    Setting.set('allow_simple_signup', false, 'Permitir cadastro simples sem pagamento')
    Setting.set('trial_days', 14, 'Número de dias de trial gratuito')
    Setting.set('stripe_webhook_enabled', true, 'Habilitar webhooks do Stripe')
    Setting.set('max_links_per_user', 100, 'Número máximo de links por usuário')
    
    redirect_to admin_settings_path, notice: 'Configurações padrão restauradas.'
  end
  
  private
  
  def setting_params
    params.require(:setting).permit(:key, :value, :description)
  end
  
  def ensure_admin
    # Por enquanto, vamos verificar se é o primeiro usuário ou se tem email específico
    unless current_user.id == 1 || current_user.email.ends_with?('@unitymob.com.br')
      redirect_to root_path, alert: 'Acesso negado.'
    end
  end
end
