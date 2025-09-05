module ShopeeAffiliate
  class BackfillJob < ApplicationJob
    queue_as :low_priority
    
    # Backfill can take longer, so more retries with longer waits
    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    def perform(integration_id, days: 30)
      integration = ShopeeAffiliateIntegration.find_by(id: integration_id)
      
      unless integration
        Rails.logger.error "ShopeeAffiliateIntegration not found for backfill: #{integration_id}"
        return
      end

      unless integration.active?
        Rails.logger.info "Skipping backfill for inactive integration: #{integration_id}"
        return
      end

      sync_service = SyncService.new(integration)
      
      Rails.logger.info "Starting backfill for user #{integration.user_id} - #{days} days"
      
      result = sync_service.backfill_conversions(days: days)
      
      if result[:success]
        Rails.logger.info "Backfill completed for user #{integration.user_id}: #{result[:message]}"
        
        # Mark backfill as completed
        integration.update!(last_error: "Backfill completed: #{result[:message]}")
      else
        Rails.logger.error "Backfill failed for user #{integration.user_id}: #{result[:message]}"
      end

      result
    end

    # Schedule backfill for a specific user
    def self.backfill_user(user_id, days: 30)
      integration = ShopeeAffiliateIntegration.find_by(user_id: user_id, active: true)
      
      if integration
        perform_later(integration.id, days)
        Rails.logger.info "Backfill scheduled for user #{user_id} - #{days} days"
        true
      else
        Rails.logger.error "No active Shopee integration found for user #{user_id}"
        false
      end
    end
  end
end
