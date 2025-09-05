module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_admin!, if: :admin_area?
    before_action :ensure_super_admin!, if: :super_admin_area?
  end

  private

  def ensure_admin!
    unless current_user&.admin? || current_user&.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Você precisa ser um administrador.'
    end
  end

  def ensure_super_admin!
    unless current_user&.super_admin?
      redirect_to root_path, alert: 'Acesso negado. Você precisa ser um super administrador.'
    end
  end

  def admin_area?
    false # Sobrescrever nos controllers que precisam
  end

  def super_admin_area?
    false # Sobrescrever nos controllers que precisam
  end
end
