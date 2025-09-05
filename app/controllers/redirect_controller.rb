class RedirectController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @link = Link.find_by_short_code(params[:short_code])
    
    if @link && @link.active?
      @link.increment_clicks!
      redirect_to @link.original_url, allow_other_host: true
    else
      redirect_to root_path, alert: 'Link não encontrado ou inativo.'
    end
  end
end
