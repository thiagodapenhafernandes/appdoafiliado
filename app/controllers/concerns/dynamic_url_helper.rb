module DynamicUrlHelper
  extend ActiveSupport::Concern

  def current_base_url
    if respond_to?(:request) && request
      "#{request.protocol}#{request.host_with_port}"
    else
      ENV['APP_URL'] || 'https://dev.unitymob.com.br'
    end
  end

  def generate_dynamic_short_url(link, req = nil)
    slug = link.custom_slug.presence || link.short_code
    base_url = if req
                 "#{req.protocol}#{req.host_with_port}"
               elsif respond_to?(:request) && request
                 "#{request.protocol}#{request.host_with_port}"
               else
                 ENV['APP_URL'] || 'https://dev.unitymob.com.br'
               end
    "#{base_url}/go/#{slug}"
  end
end
