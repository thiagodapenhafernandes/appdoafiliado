module ShopeeAffiliate
  class SyncService
    attr_reader :integration, :client

    def initialize(integration)
      @integration = integration
      @client = Client.new(integration)
    end

    def sync_recent_conversions(days_back: 7)
      return sync_result(false, 'Integration not active') unless integration.active?
      return sync_result(false, 'Invalid credentials') unless integration.connected?

      start_date = calculate_start_date(days_back)
      end_date = Time.current
      
      Rails.logger.info "Starting Shopee sync for user #{integration.user_id} from #{start_date} to #{end_date}"

      begin
        sync_conversions_for_period(start_date, end_date)
      rescue => e
        handle_sync_error(e)
      end
    end

    def sync_conversions_for_period(start_date, end_date)
      total_processed = 0
      total_created = 0
      total_errors = 0
      page = 1
      has_more = true

      while has_more
        Rails.logger.info "Fetching page #{page} for user #{integration.user_id}"
        
        response = client.fetch_conversions(
          start_date: start_date.strftime('%Y-%m-%d'),
          end_date: end_date.strftime('%Y-%m-%d'),
          page: page,
          limit: 100
        )

        if response[:error]
          return sync_result(false, response[:error])
        end

        conversions = response[:conversions] || []
        pagination = response[:pagination] || {}

        if conversions.any?
          result = process_conversions_batch(conversions)
          total_processed += conversions.count
          total_created += result[:created]
          total_errors += result[:errors]

          Rails.logger.info "Page #{page}: #{conversions.count} conversions, #{result[:created]} created, #{result[:errors]} errors"
        end

        has_more = pagination['hasNextPage'] == true && conversions.any?
        page += 1

        # Safety break to avoid infinite loops
        break if page > 100
      end

      update_integration_status(true, total_processed, total_created, total_errors)
      sync_result(true, "Processed #{total_processed} conversions, created #{total_created}")

    rescue => e
      Rails.logger.error "Sync error for user #{integration.user_id}: #{e.message}"
      handle_sync_error(e)
    end

    def backfill_conversions(days: 30)
      Rails.logger.info "Starting backfill for user #{integration.user_id} - #{days} days"
      
      start_date = days.days.ago
      end_date = Time.current
      
      sync_conversions_for_period(start_date, end_date)
    end

    private

    def calculate_start_date(days_back)
      # Use last sync date if available, otherwise go back specified days
      if integration.last_sync_at.present?
        # Overlap by 1 hour to catch any delayed conversions
        [integration.last_sync_at - 1.hour, days_back.days.ago].max
      else
        days_back.days.ago
      end
    end

    def process_conversions_batch(conversions)
      result = ConversionParser.batch_parse(integration.user, conversions)
      created_count = 0
      error_count = 0

      # Create AffiliateConversions
      result[:success].each do |conversion_data|
        begin
          conversion = AffiliateConversion.create!(conversion_data)
          created_count += 1
          
          # Also create in main commissions table if completed
          if conversion.completed?
            create_commission_record(conversion)
          end
        rescue => e
          Rails.logger.error "Failed to create conversion #{conversion_data[:external_id]}: #{e.message}"
          error_count += 1
        end
      end

      Rails.logger.info "Batch result: #{created_count} created, #{result[:duplicates].count} duplicates, #{result[:errors].count + error_count} errors"

      {
        created: created_count,
        duplicates: result[:duplicates].count,
        errors: result[:errors].count + error_count
      }
    end

    def create_commission_record(affiliate_conversion)
      # Avoid duplicates in main commission table
      return if Commission.exists?(external_id: affiliate_conversion.external_id, user_id: affiliate_conversion.user_id)

      Commission.create!(affiliate_conversion.to_commission_attributes)
    rescue => e
      Rails.logger.error "Failed to create commission for conversion #{affiliate_conversion.external_id}: #{e.message}"
    end

    def update_integration_status(success, processed = 0, created = 0, errors = 0)
      integration.update!(
        last_sync_at: Time.current,
        sync_count: integration.sync_count + 1,
        last_error: success ? nil : "Processed: #{processed}, Created: #{created}, Errors: #{errors}"
      )
    end

    def sync_result(success, message)
      {
        success: success,
        message: message,
        user_id: integration.user_id,
        timestamp: Time.current
      }
    end

    def handle_sync_error(error)
      error_message = "Sync failed: #{error.message}"
      integration.update!(last_error: error_message)
      Rails.logger.error "User #{integration.user_id}: #{error_message}"
      
      sync_result(false, error_message)
    end
  end
end
