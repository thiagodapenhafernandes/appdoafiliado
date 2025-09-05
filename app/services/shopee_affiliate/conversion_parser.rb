module ShopeeAffiliate
  class ConversionParser
    attr_reader :user, :raw_data

    def initialize(user, raw_conversion_data)
      @user = user
      @raw_data = raw_conversion_data
    end

    def parse
      return nil unless valid_data?

      {
        user_id: user.id,
        external_id: extract_external_id,
        order_id: raw_data['orderId'],
        item_id: raw_data['itemId'],
        category: extract_category,
        channel: extract_channel,
        sub_id: extract_sub_id,
        commission_cents: extract_commission_cents,
        currency: extract_currency,
        quantity: extract_quantity,
        click_time: parse_datetime(raw_data['clickTime']),
        conversion_time: parse_datetime(raw_data['conversionTime']),
        status: normalize_status(raw_data['status']),
        source: 'shopee_api',
        raw_data: raw_data,
        purchase_value: extract_purchase_value,
        commission_rate: extract_commission_rate
      }
    end

    def parse_to_commission_format
      parsed = parse
      return nil unless parsed

      {
        user_id: user.id,
        order_id: parsed[:order_id],
        external_id: parsed[:external_id],
        source: 'shopee_api',
        channel: parsed[:channel] || 'Shopee',
        commission_amount: parsed[:commission_cents] / 100.0,
        sale_amount: parsed[:purchase_value],
        order_status: parsed[:status] == 'completed' ? 'completed' : 'pending',
        commission_type: 'shopee',
        product_name: extract_product_name,
        category: parsed[:category],
        order_date: parsed[:conversion_time],
        commission_date: parsed[:conversion_time],
        item_id: parsed[:item_id],
        item_name: extract_product_name,
        quantity: parsed[:quantity],
        purchase_value: parsed[:purchase_value],
        affiliate_commission: parsed[:commission_cents] / 100.0,
        affiliate_status: parsed[:status]&.capitalize,
        attribution_type: 'Pedido via API Shopee',
        sub_id1: parsed[:sub_id]
      }
    end

    def self.batch_parse(user, conversions_array)
      results = {
        success: [],
        errors: [],
        duplicates: []
      }

      conversions_array.each do |conversion_data|
        begin
          parser = new(user, conversion_data)
          parsed = parser.parse
          
          if parsed
            # Check for duplicates
            if AffiliateConversion.exists?(user_id: user.id, external_id: parsed[:external_id])
              results[:duplicates] << parsed[:external_id]
            else
              results[:success] << parsed
            end
          else
            results[:errors] << "Invalid data: #{conversion_data['id'] || 'unknown'}"
          end
        rescue => e
          results[:errors] << "Parse error for #{conversion_data['id'] || 'unknown'}: #{e.message}"
        end
      end

      results
    end

    private

    def valid_data?
      raw_data.is_a?(Hash) && 
      raw_data['id'].present? && 
      raw_data['conversionTime'].present?
    end

    def extract_external_id
      raw_data['id']&.to_s
    end

    def extract_category
      raw_data['category'] || 'General'
    end

    def extract_channel
      raw_data['channel'] || 'Shopee'
    end

    def extract_sub_id
      # Pode vir como 'subId', 'sub_id', ou dentro de raw data
      raw_data['subId'] || raw_data['sub_id'] || raw_data.dig('tracking', 'subId')
    end

    def extract_commission_cents
      commission = raw_data['commissionAmount'] || 0
      (commission.to_f * 100).to_i
    end

    def extract_currency
      raw_data['currency'] || 'BRL'
    end

    def extract_quantity
      (raw_data['quantity'] || 1).to_i
    end

    def extract_purchase_value
      raw_data['purchaseValue']&.to_f || 0.0
    end

    def extract_commission_rate
      raw_data['commissionRate']&.to_f || 0.0
    end

    def extract_product_name
      raw_data['productName'] || raw_data['itemName'] || "Product #{raw_data['itemId']}"
    end

    def parse_datetime(datetime_string)
      return nil if datetime_string.blank?
      
      # Handle different datetime formats from Shopee API
      formats = [
        '%Y-%m-%d %H:%M:%S',
        '%Y-%m-%dT%H:%M:%S',
        '%Y-%m-%dT%H:%M:%S.%LZ',
        '%Y-%m-%dT%H:%M:%SZ'
      ]

      formats.each do |format|
        begin
          return DateTime.strptime(datetime_string, format)
        rescue ArgumentError
          next
        end
      end

      # If all formats fail, try to parse with Time.parse
      Time.parse(datetime_string) rescue nil
    end

    def normalize_status(status)
      case status&.downcase
      when 'completed', 'confirmed', 'paid'
        'completed'
      when 'pending', 'processing', 'waiting'
        'pending'
      when 'cancelled', 'canceled', 'rejected'
        'cancelled'
      else
        'pending'
      end
    end
  end
end
