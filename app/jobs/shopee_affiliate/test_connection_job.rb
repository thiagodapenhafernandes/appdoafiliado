module ShopeeAffiliate
  class TestConnectionJob < ApplicationJob
    queue_as :default
    
    def perform(integration_id)
      integration = ShopeeAffiliateIntegration.find_by(id: integration_id)
      
      unless integration
        Rails.logger.error "ShopeeAffiliateIntegration not found for connection test: #{integration_id}"
        return { success: false, message: 'Integration not found' }
      end

      Rails.logger.info "Testing connection for user #{integration.user_id}"
      
      begin
        client = Client.new(integration)
        success = client.test_connection
        
        if success
          integration.update!(last_error: nil)
          Rails.logger.info "Connection test successful for user #{integration.user_id}"
          { success: true, message: 'Connection successful' }
        else
          error_msg = 'Connection test failed - check credentials'
          integration.update!(last_error: error_msg)
          Rails.logger.error "Connection test failed for user #{integration.user_id}"
          { success: false, message: error_msg }
        end
      rescue => e
        error_msg = "Connection error: #{e.message}"
        integration.update!(last_error: error_msg)
        Rails.logger.error "Connection test error for user #{integration.user_id}: #{e.message}"
        { success: false, message: error_msg }
      end
    end

    # Test connection for a specific user
    def self.test_user_connection(user_id)
      integration = ShopeeAffiliateIntegration.find_by(user_id: user_id)
      
      if integration
        perform_later(integration.id)
        true
      else
        false
      end
    end
  end
end
