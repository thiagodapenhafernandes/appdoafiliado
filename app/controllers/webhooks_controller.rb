class WebhooksController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :verify_webhook_signature

  def stripe
    event = Stripe::Event.construct_from(params.to_unsafe_h.except(:controller, :action))
    
    StripeService.handle_webhook(event)
    
    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid payload: #{e.message}"
    head :bad_request
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.error "Invalid signature: #{e.message}"
    head :bad_request
  rescue StandardError => e
    Rails.logger.error "Webhook error: #{e.message}"
    head :internal_server_error
  end

  private

  def verify_webhook_signature
    payload = request.body.read
    signature = request.env['HTTP_STRIPE_SIGNATURE']
    
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']
    return unless endpoint_secret.present?

    Stripe::Webhook.construct_event(payload, signature, endpoint_secret)
  rescue Stripe::SignatureVerificationError
    Rails.logger.error "Webhook signature verification failed"
    head :bad_request
  end
end
