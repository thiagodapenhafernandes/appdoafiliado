module ShopeeAffiliate
  class SyncConversionsJob < ApplicationJob
    queue_as :default
    
    # Retry configuration for API failures
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(integration_id, options = {})
      integration = ShopeeAffiliateIntegration.find_by(id: integration_id)
      
      unless integration
        Rails.logger.error "ShopeeAffiliateIntegration not found: #{integration_id}"
        return
      end

      unless integration.active?
        Rails.logger.info "Skipping sync for inactive integration: #{integration_id}"
        return
      end

      sync_service = SyncService.new(integration)
      days_back = options[:days_back] || 7
      
      Rails.logger.info "Starting scheduled sync for user #{integration.user_id}"
      
      result = sync_service.sync_recent_conversions(days_back: days_back)
      
      if result[:success]
        Rails.logger.info "Sync completed for user #{integration.user_id}: #{result[:message]}"
      else
        Rails.logger.error "Sync failed for user #{integration.user_id}: #{result[:message]}"
        
        # Notify user about sync failure (could be implemented later)
        # UserMailer.sync_failed(integration.user, result[:message]).deliver_later
      end

      result
    end

    # Schedule sync for all active integrations
    def self.sync_all_users(days_back: 7)
      ShopeeAffiliateIntegration.active.find_each do |integration|
        perform_later(integration.id, { days_back: days_back })
      end
    end

    # Schedule immediate sync for a specific user
    def self.sync_user_now(user_id, days_back: 7)
      integration = ShopeeAffiliateIntegration.find_by(user_id: user_id, active: true)
      
      if integration
        perform_later(integration.id, { days_back: days_back })
        true
      else
        false
      end
    end
  end
end
