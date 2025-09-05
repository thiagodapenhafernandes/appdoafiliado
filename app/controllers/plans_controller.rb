class PlansController < ApplicationController
  # Permitir acesso público aos planos
  skip_before_action :authenticate_user!

  def index
    @plans = Plan.all.order(:price_cents)
  end

  def show
    @plan = Plan.find(params[:id])
  end
end
