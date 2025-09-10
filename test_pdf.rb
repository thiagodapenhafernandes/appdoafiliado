#!/usr/bin/env ruby

require 'prawn'
require 'prawn/table'

begin
  puts "Testando geração de PDF..."
  
  pdf = Prawn::Document.new do |pdf|
    pdf.font 'Helvetica'
    pdf.text "Teste de PDF", size: 20
    pdf.move_down 20
    pdf.text "Este é um teste para verificar se o Prawn funciona corretamente."
  end
  
  File.open('/tmp/test.pdf', 'wb') do |file|
    file.write(pdf.render)
  end
  
  puts "✅ PDF gerado com sucesso em /tmp/test.pdf"
  puts "Tamanho do arquivo: #{File.size('/tmp/test.pdf')} bytes"
  
rescue => e
  puts "❌ Erro ao gerar PDF: #{e.message}"
  puts e.backtrace.join("\n")
end
