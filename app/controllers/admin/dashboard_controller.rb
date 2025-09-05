class Admin::DashboardController < Admin::BaseController
  def index
    @users_count = User.count
    @plans_count = Plan.count
    @total_revenue = Subscription.active.joins(:plan)
                                 .sum('plans.price_cents')
    @recent_subscriptions = Subscription.includes(:user, :plan)
                                      .order(created_at: :desc)
                                      .limit(10)
  end
end
