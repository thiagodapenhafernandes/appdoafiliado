#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== Simulando método performance_by_subid_with_details CORRIGIDO ==="

# Simular exatamente o que está no controller agora
user_id = 1
commissions = Commission.where(user_id: user_id).where.not(order_status: 'cancelled')

# Método novo (deveria incluir todos os registros)
data = commissions.select(
  'sub_id1',
  'COUNT(*) as orders_count',
  'SUM(affiliate_commission) as total_commission',
  'SUM(purchase_value) as total_sales'
).group(:sub_id1).order('total_commission DESC').limit(50)

puts "Resultados da consulta corrigida:"
data.each do |row|
  subid_display = row.sub_id1.present? ? row.sub_id1 : 'Não informado'
  puts "SubID: #{subid_display} | Pedidos: #{row.orders_count} | Comissão: R$ #{row.total_commission} | Vendas: R$ #{row.total_sales}"
end

puts ""
puts "Total de linhas retornadas: #{data.length}"
total_commission_sum = 0
data.each { |row| total_commission_sum += row.total_commission.to_f }
puts "Soma total das comissões: R$ #{total_commission_sum}"

# Verificar se ainda há algum filtro excluindo registros
puts ""
puts "=== Verificação de filtros ==="
puts "Total de comissões do usuário (sem filtro de status): #{Commission.where(user_id: user_id).count}"
puts "Total de comissões do usuário (com filtro de status != 'cancelled'): #{commissions.count}"
puts "Soma total de comissões (sem filtro de status): R$ #{Commission.where(user_id: user_id).sum(:affiliate_commission)}"
puts "Soma total de comissões (com filtro de status): R$ #{commissions.sum(:affiliate_commission)}"
