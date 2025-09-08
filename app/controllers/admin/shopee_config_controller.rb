class Admin::ShopeeConfigController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin

  def index
    # Configurações do Shopee
  end

  def update
    # Atualizar configurações do Shopee
    redirect_to admin_shopee_config_index_path, notice: 'Configurações atualizadas com sucesso!'
  end

  private

  def ensure_admin
    redirect_to root_path unless current_user&.admin?
  end
end
