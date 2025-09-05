class Admin::BaseController < ApplicationController
  include AdminAuthorization
  
  before_action :authenticate_user!
  layout 'admin'

  private

  def admin_area?
    true
  end
end
