class ApplicationController < ActionController::Base
  # Concerns
  include DynamicUrlHelper
  
  # Security
  protect_from_forgery with: :exception

  # Authentication
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Flash messages helper
  def flash_message(type, message)
    flash[type] = message
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone])
  end
end
