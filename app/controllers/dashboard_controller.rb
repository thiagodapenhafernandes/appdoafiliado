class DashboardController < ApplicationController
  before_action :redirect_guests_to_plans

  def index
    @user = current_user
    @links = current_user.links.active.limit(5).order(created_at: :desc)
    @links_count = current_user.links.active.count
    @total_clicks = current_user.links.sum(:clicks_count)
    @commissions = current_user.commissions.includes(:user).limit(10).order(created_at: :desc)
    @total_commissions = current_user.commissions.total_commissions
    @total_sales = current_user.commissions.total_sales
    @orders_count = current_user.commissions.count
    @request = request
    
    # Stats for charts
    @links_by_clicks = current_user.links.active.by_clicks.limit(5)
  end

  private

  def redirect_guests_to_plans
    redirect_to plans_path unless user_signed_in?
  end
end
