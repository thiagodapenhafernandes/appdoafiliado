module ShopeeAffiliate
  class Client
    include HTTParty
    
    attr_reader :integration, :auth_service
    
    def initialize(integration)
      @integration = integration
      @auth_service = AuthService.new(integration)
      self.class.base_uri integration.endpoint
    end

    def test_connection
      query = {
        query: <<~GRAPHQL
          query {
            __typename
          }
        GRAPHQL
      }

      response = post('/', query)
      
      if response.success?
        Rails.logger.info "Shopee API connection successful for user #{integration.user_id}"
        true
      else
        Rails.logger.error "Shopee API connection failed: #{response.body}"
        false
      end
    rescue => e
      Rails.logger.error "Shopee API connection error: #{e.message}"
      false
    end

    def fetch_conversions(start_date:, end_date:, page: 1, limit: 100)
      query = build_conversions_query(start_date, end_date, page, limit)
      
      response = post('/', { query: query })
      
      if response.success?
        parse_conversions_response(response.parsed_response)
      else
        handle_api_error(response)
      end
    rescue => e
      Rails.logger.error "Failed to fetch conversions: #{e.message}"
      { error: e.message, conversions: [] }
    end

    private

    def post(path, payload)
      body = payload.to_json
      headers = auth_service.headers(body)
      
      self.class.post(path, {
        body: body,
        headers: headers,
        timeout: 30
      })
    end

    def build_conversions_query(start_date, end_date, page, limit)
      <<~GRAPHQL
        query GetConversions($startDate: String!, $endDate: String!, $page: Int!, $limit: Int!) {
          conversions(
            startDate: $startDate,
            endDate: $endDate,
            page: $page,
            limit: $limit
          ) {
            data {
              id
              orderId
              itemId
              productName
              category
              channel
              subId
              commissionAmount
              currency
              quantity
              clickTime
              conversionTime
              status
              purchaseValue
              commissionRate
            }
            pagination {
              currentPage
              totalPages
              totalItems
              hasNextPage
            }
          }
        }
      GRAPHQL
    end

    def parse_conversions_response(response)
      return { error: 'Invalid response format', conversions: [] } unless response.is_a?(Hash)
      
      data = response.dig('data', 'conversions')
      return { error: 'No conversion data found', conversions: [] } unless data

      {
        conversions: data['data'] || [],
        pagination: data['pagination'] || {},
        error: nil
      }
    end

    def handle_api_error(response)
      error_message = response.parsed_response&.dig('errors')&.first&.dig('message') || 
                     "HTTP #{response.code}: #{response.message}"
      
      Rails.logger.error "Shopee API error: #{error_message}"
      
      {
        error: error_message,
        conversions: [],
        status_code: response.code
      }
    end
  end
end
