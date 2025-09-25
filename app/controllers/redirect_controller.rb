class RedirectController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @link = Link.find_by_short_code(params[:short_code])
    
    if @link && @link.active?
      @link.increment_clicks!

      if @link.advanced_tracking?
        WebsiteClick.create(
          link: @link,
          user: @link.user,
          click_id: SecureRandom.uuid,
          click_time: Time.current,
          region: request.location.try(:country) || 'Desconhecido',
          sub_id: params[:sub_id],
          referrer: request.referer,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
      end

      redirect_to @link.original_url, allow_other_host: true
    else
      redirect_to root_path, alert: 'Link não encontrado ou inativo.'
    end
  end
end
