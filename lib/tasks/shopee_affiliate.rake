namespace :shopee_affiliate do
  desc "Backfill conversions for a specific user"
  task :backfill, [:user_id, :days] => :environment do |t, args|
    user_id = args[:user_id]
    days = (args[:days] || 30).to_i

    unless user_id
      puts "Usage: rake shopee_affiliate:backfill[USER_ID,DAYS]"
      puts "Example: rake shopee_affiliate:backfill[1,30]"
      exit 1
    end

    user = User.find_by(id: user_id)
    unless user
      puts "User not found: #{user_id}"
      exit 1
    end

    integration = user.shopee_affiliate_integration
    unless integration&.active?
      puts "No active Shopee integration found for user #{user_id}"
      exit 1
    end

    puts "Starting backfill for user #{user_id} (#{user.email}) - #{days} days..."
    
    begin
      sync_service = ShopeeAffiliate::SyncService.new(integration)
      result = sync_service.backfill_conversions(days: days)
      
      if result[:success]
        puts "✅ Backfill completed: #{result[:message]}"
      else
        puts "❌ Backfill failed: #{result[:message]}"
        exit 1
      end
    rescue => e
      puts "❌ Error during backfill: #{e.message}"
      exit 1
    end
  end

  desc "Sync recent conversions for all active users"
  task :sync_all, [:days] => :environment do |t, args|
    days = (args[:days] || 7).to_i
    
    puts "Starting sync for all active integrations - #{days} days back..."
    
    active_integrations = ShopeeAffiliateIntegration.active.includes(:user)
    
    if active_integrations.empty?
      puts "No active Shopee integrations found"
      exit 0
    end

    puts "Found #{active_integrations.count} active integrations"
    
    results = []
    
    active_integrations.each do |integration|
      puts "\n📋 Syncing user #{integration.user_id} (#{integration.user.email})..."
      
      begin
        sync_service = ShopeeAffiliate::SyncService.new(integration)
        result = sync_service.sync_recent_conversions(days_back: days)
        
        results << {
          user_id: integration.user_id,
          email: integration.user.email,
          success: result[:success],
          message: result[:message]
        }
        
        if result[:success]
          puts "  ✅ #{result[:message]}"
        else
          puts "  ❌ #{result[:message]}"
        end
      rescue => e
        error_msg = "Error: #{e.message}"
        results << {
          user_id: integration.user_id,
          email: integration.user.email,
          success: false,
          message: error_msg
        }
        puts "  ❌ #{error_msg}"
      end
    end

    # Summary
    successful = results.count { |r| r[:success] }
    failed = results.count { |r| !r[:success] }
    
    puts "\n📊 SUMMARY:"
    puts "  Total: #{results.count}"
    puts "  ✅ Successful: #{successful}"
    puts "  ❌ Failed: #{failed}"
    
    if failed > 0
      puts "\n❌ Failed syncs:"
      results.select { |r| !r[:success] }.each do |result|
        puts "  - #{result[:email]}: #{result[:message]}"
      end
    end
  end

  desc "Test connection for a specific user"
  task :test_connection, [:user_id] => :environment do |t, args|
    user_id = args[:user_id]

    unless user_id
      puts "Usage: rake shopee_affiliate:test_connection[USER_ID]"
      exit 1
    end

    user = User.find_by(id: user_id)
    unless user
      puts "User not found: #{user_id}"
      exit 1
    end

    integration = user.shopee_affiliate_integration
    unless integration
      puts "No Shopee integration found for user #{user_id}"
      exit 1
    end

    puts "Testing connection for user #{user_id} (#{user.email})..."
    puts "App ID: #{integration.app_id}"
    puts "Endpoint: #{integration.endpoint}"
    puts "Active: #{integration.active?}"

    begin
      client = ShopeeAffiliate::Client.new(integration)
      success = client.test_connection
      
      if success
        puts "✅ Connection successful!"
      else
        puts "❌ Connection failed - check credentials and API status"
        exit 1
      end
    rescue => e
      puts "❌ Connection error: #{e.message}"
      exit 1
    end
  end

  desc "Show status of all Shopee integrations"
  task :status => :environment do
    integrations = ShopeeAffiliateIntegration.includes(:user, :affiliate_conversions)
    
    if integrations.empty?
      puts "No Shopee integrations found"
      exit 0
    end

    puts "📊 SHOPEE AFFILIATE INTEGRATIONS STATUS\n"
    puts "%-5s %-25s %-12s %-8s %-15s %-10s %s" % ['ID', 'User Email', 'App ID', 'Active', 'Last Sync', 'Conv.', 'Status']
    puts "-" * 90

    integrations.each do |integration|
      conversions_count = integration.affiliate_conversions.count
      last_sync = integration.last_sync_at ? integration.last_sync_at.strftime('%m/%d %H:%M') : 'Never'
      status = integration.last_error.present? ? 'Error' : 'OK'
      
      puts "%-5s %-25s %-12s %-8s %-15s %-10s %s" % [
        integration.id,
        integration.user.email.truncate(25),
        integration.app_id.truncate(12),
        integration.active? ? 'Yes' : 'No',
        last_sync,
        conversions_count,
        status
      ]
      
      if integration.last_error.present?
        puts "      Error: #{integration.last_error.truncate(60)}"
      end
    end

    puts "\n📈 SUMMARY:"
    puts "Total integrations: #{integrations.count}"
    puts "Active: #{integrations.active.count}"
    puts "With errors: #{integrations.where.not(last_error: nil).count}"
    puts "Total conversions: #{AffiliateConversion.count}"
  end

  desc "Schedule periodic sync jobs (for cron)"
  task :schedule_sync => :environment do
    puts "Scheduling sync jobs for all active users..."
    
    scheduled = 0
    ShopeeAffiliateIntegration.active.find_each do |integration|
      ShopeeAffiliate::SyncConversionsJob.perform_later(integration.id, { days_back: 1 })
      scheduled += 1
    end
    
    puts "✅ Scheduled #{scheduled} sync jobs"
  end
end
