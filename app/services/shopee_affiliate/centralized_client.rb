# app/services/shopee_affiliate/centralized_client.rb
module ShopeeAffiliate
  class CentralizedClient
    include HTTParty
    
    # Credenciais master do LinkFlow
    MASTER_APP_ID = ENV['SHOPEE_MASTER_APP_ID']
    MASTER_SECRET = ENV['SHOPEE_MASTER_SECRET']
    
    base_uri 'https://open-api.affiliate.shopee.com.br/graphql'
    
    def initialize(user_integration)
      @integration = user_integration
    end
    
    def fetch_conversions_for_user(start_date:, end_date:, page: 1, limit: 100)
      query = build_user_conversions_query(start_date, end_date, page, limit)
      
      headers = master_auth_headers(query)
      
      response = self.class.post('/', {
        body: { query: query, variables: user_variables }.to_json,
        headers: headers
      })
      
      handle_response(response)
    end
    
    def test_user_connection
      # Testa se as credenciais do usuário são válidas
      query = build_user_test_query
      
      headers = master_auth_headers(query)
      
      response = self.class.post('/', {
        body: { query: query, variables: user_variables }.to_json,
        headers: headers
      })
      
      response.success? && response.parsed_response.dig('data')
    end
    
    private
    
    def master_auth_headers(payload)
      timestamp = Time.current.to_i
      signature = generate_master_signature(payload, timestamp)
      
      {
        'Content-Type' => 'application/json',
        'X-APP-ID' => MASTER_APP_ID,
        'X-TIMESTAMP' => timestamp.to_s,
        'X-SIGNATURE' => signature,
        'X-USER-TOKEN' => @integration.access_token # Token do usuário específico
      }
    end
    
    def generate_master_signature(payload, timestamp)
      data = "#{MASTER_APP_ID}#{timestamp}#{payload}#{MASTER_SECRET}"
      Digest::SHA256.hexdigest(data)
    end
    
    def user_variables
      {
        user_id: @integration.shopee_user_id,
        access_token: @integration.access_token
      }
    end
    
    def build_user_conversions_query(start_date, end_date, page, limit)
      <<~GRAPHQL
        query GetUserConversions($user_id: String!, $access_token: String!, $start_date: String!, $end_date: String!, $page: Int!, $limit: Int!) {
          affiliate {
            user(id: $user_id, token: $access_token) {
              conversions(
                start_date: $start_date,
                end_date: $end_date,
                page: $page,
                limit: $limit
              ) {
                data {
                  id
                  order_id
                  item_id
                  commission_amount
                  click_time
                  conversion_time
                  status
                  sub_id1
                  sub_id2
                  sub_id3
                  channel
                }
                pagination {
                  current_page
                  total_pages
                  has_next_page
                }
              }
            }
          }
        }
      GRAPHQL
    end
    
    def build_user_test_query
      <<~GRAPHQL
        query TestUserConnection($user_id: String!, $access_token: String!) {
          affiliate {
            user(id: $user_id, token: $access_token) {
              id
              email
              status
            }
          }
        }
      GRAPHQL
    end
    
    def handle_response(response)
      if response.success?
        data = response.parsed_response
        
        if data['errors']
          Rails.logger.error "Shopee API errors: #{data['errors']}"
          { success: false, errors: data['errors'] }
        else
          { success: true, data: data['data'] }
        end
      else
        Rails.logger.error "Shopee API request failed: #{response.code} - #{response.body}"
        { success: false, error: "HTTP #{response.code}: #{response.message}" }
      end
    end
  end
end
