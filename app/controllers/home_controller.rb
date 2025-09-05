class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to dashboard_path
    else
      # Serve the landing page for non-logged users
      render file: Rails.root.join('public', 'site', 'index.html'), layout: false
    end
  end
end
