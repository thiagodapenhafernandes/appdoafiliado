module ShopeeAffiliate
  class AuthService
    attr_reader :app_id, :secret, :endpoint

    def initialize(integration)
      @app_id = integration.app_id
      @secret = integration.secret
      @endpoint = integration.endpoint
    end

    def headers(payload = '')
      timestamp = Time.current.to_i
      signature = generate_signature(payload, timestamp)

      {
        'Content-Type' => 'application/json',
        'X-APP-ID' => app_id,
        'X-TIMESTAMP' => timestamp.to_s,
        'X-SIGNATURE' => signature
      }
    end

    def generate_signature(payload, timestamp)
      # Shopee signature format: SHA256(app_id + timestamp + payload + secret)
      data = "#{app_id}#{timestamp}#{payload}#{secret}"
      Digest::SHA256.hexdigest(data)
    end

    def valid_credentials?
      app_id.present? && secret.present?
    end

    private

    def hmac_signature(payload, timestamp)
      # Alternative HMAC approach if needed
      data = "#{app_id}#{timestamp}#{payload}"
      OpenSSL::HMAC.hexdigest('SHA256', secret, data)
    end
  end
end
