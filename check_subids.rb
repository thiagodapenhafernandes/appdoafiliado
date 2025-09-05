#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== Verificação de dados SubID ==="
puts "Total de comissões: #{Commission.count}"
puts "Com SubID (não nulo/vazio): #{Commission.where.not(sub_id1: [nil, '']).count}"
puts "Sem SubID (nulo ou vazio): #{Commission.where(sub_id1: [nil, '']).count}"
puts "SubIDs únicos: #{Commission.distinct.count(:sub_id1)}"
puts ""

puts "=== Primeiros 5 registros sem SubID ==="
Commission.where(sub_id1: [nil, '']).limit(5).each do |c|
  puts "ID: #{c.id}, Order: #{c.order_id}, SubID1: '#{c.sub_id1}', Commission: #{c.affiliate_commission}"
end
puts ""

puts "=== Análise do método atual vs correto ==="
puts "Método ANTIGO (excluindo nulos):"
old_data = Commission.where.not(sub_id1: [nil, '']).group(:sub_id1).sum(:affiliate_commission)
puts "Total de SubIDs: #{old_data.keys.count}"
puts "Total de comissão: #{old_data.values.sum}"

puts ""
puts "Método NOVO (incluindo todos):"
new_data = Commission.group(:sub_id1).sum(:affiliate_commission)
puts "Total de SubIDs: #{new_data.keys.count}"
puts "Total de comissão: #{new_data.values.sum}"

puts ""
puts "Diferença encontrada:"
nulos = new_data[nil] || 0
vazios = new_data[''] || 0
puts "Comissão de registros com SubID nulo: #{nulos}"
puts "Comissão de registros com SubID vazio: #{vazios}"
puts "Total de comissão dos 'Não informado': #{nulos + vazios}"
