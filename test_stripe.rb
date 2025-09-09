ENV['RAILS_ENV'] = 'production'
require_relative 'config/environment'
require 'stripe'

puts "Testando conexão com Stripe..."
puts "Ambiente: #{Rails.env}"

begin
  # Testa conexão básica
  products = Stripe::Product.list(limit: 1)
  puts "✅ Conectado com Stripe com sucesso!"
  puts "Número de produtos encontrados: #{products.data.count}"
  
  # Testa preços
  prices = Stripe::Price.list(limit: 1)
  puts "Número de preços encontrados: #{prices.data.count}"
  
  # Mostra a chave que está sendo usada (apenas primeiros caracteres)
  puts "Chave Stripe: #{Stripe.api_key[0..10]}..."
  
rescue Stripe::AuthenticationError => e
  puts "❌ Erro de autenticação Stripe: #{e.message}"
rescue Stripe::APIConnectionError => e
  puts "❌ Erro de conexão Stripe: #{e.message}"
rescue => e
  puts "❌ Erro geral: #{e.message}"
  puts e.backtrace
end
