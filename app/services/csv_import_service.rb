require 'csv'

class CsvImportService
  attr_reader :user, :file_path, :errors

  def initialize(user, file_path)
    @user = user
    @file_path = file_path
    @errors = []
  end

  def import
    return false unless valid_file?
    
    begin
      import_commissions
      true
    rescue => e
      @errors << "Erro durante importação: #{e.message}"
      false
    end
  end

  def import_commissions
    imported_count = 0
    updated_count = 0
    
    Rails.logger.info "=== Iniciando importação do arquivo: #{file_path} ==="
    
    # Primeiro, vamos ver os headers do arquivo
    headers = []
    CSV.foreach(file_path.to_s, headers: true, encoding: 'BOM|UTF-8') do |row|
      headers = row.headers
      Rails.logger.info "Headers encontrados: #{headers.inspect}"
      break
    end
    
    CSV.foreach(file_path.to_s, headers: true, encoding: 'BOM|UTF-8') do |row|
      commission_data = parse_row(row)
      if commission_data.nil?
        next
      end
      
      commission = find_or_initialize_commission(commission_data[:order_id])
      
      if commission.persisted?
        commission.update!(commission_data)
        updated_count += 1
      else
        commission.assign_attributes(commission_data)
        commission.user = user
        commission.save!
        imported_count += 1
      end
    rescue => e
      Rails.logger.error "Erro na linha #{$.}: #{e.message}"
      @errors << "Erro na linha #{$.}: #{e.message}"
    end
    
    Rails.logger.info "=== Importação finalizada: #{imported_count} criados, #{updated_count} atualizados ==="
    { imported: imported_count, updated: updated_count }
  end

  private

  def valid_file?
    unless File.exist?(file_path)
      @errors << "Arquivo não encontrado"
      return false
    end
    
    unless file_path.to_s.end_with?('.csv')
      @errors << "Apenas arquivos CSV são suportados"
      return false
    end
    
    true
  end

  def find_or_initialize_commission(order_id)
    user.commissions.find_or_initialize_by(order_id: order_id)
  end

  def parse_row(row)
    order_id = row['ID do pedido']
    return nil if order_id.blank?
    
    {
      order_id: row['ID do pedido'],
      order_status: normalize_status(row['Status do Pedido']),
      payment_id: row['ID do pagamento'],
      order_date: parse_datetime(row['Horário do pedido']),
      completion_time: parse_datetime(row['Tempo de Conclusão']),
      click_time: parse_datetime(row['Tempo dos Cliques']),
      store_name: row['Nome da loja'],
      store_id: row['ID da loja'],
      store_type: row['Tipo da Loja'],
      item_id: row['ID do item'],
      item_name: row['Nome do Item'],
      product_type: row['Tipo de Produto'],
      category_l1: row['Categoria Global L1'],
      category_l2: row['Categoria Global L2'],
      category_l3: row['Categoria Global L3'],
      price: parse_decimal(row['Preço(R$)']),
      quantity: row['Qtd'].to_i,
      purchase_value: parse_decimal(row['Valor de Compra(R$)']),
      refund_value: parse_decimal(row['Valor do Reembolso(R$)']),
      shopee_commission_rate: parse_percentage(row['Taxa de comissão Shopee do item']),
      shopee_commission: parse_decimal(row['Comissão do Item da Shopee(R$)']),
      seller_commission_rate: parse_percentage(row['Taxa de comissão do vendedor do item']),
      seller_commission: parse_decimal(row['Comissão do Item da Marca(R$)']),
      total_item_commission: parse_decimal(row['Comissão total do item(R$)']),
      total_order_commission: parse_decimal(row['Comissão total do pedido(R$)']),
      affiliate_commission: parse_decimal(row['Comissão líquida do afiliado(R$)']),
      affiliate_status: row['Status do item do afiliado'],
      attribution_type: row['Tipo de atribuição'],
      buyer_status: row['Status do Comprador'],
      sub_id1: row['Sub_id1'],
      sub_id2: row['Sub_id2'],
      sub_id3: row['Sub_id3'],
      sub_id4: row['Sub_id4'],
      sub_id5: row['Sub_id5'],
      channel: row['Canal'],
      
      # Campos legados para manter compatibilidade
      commission_amount: parse_decimal(row['Comissão líquida do afiliado(R$)']),
      sale_amount: parse_decimal(row['Valor de Compra(R$)']),
      sub_id: row['Sub_id1'],
      product_name: row['Nome do Item'],
      category: row['Categoria Global L1'],
      commission_date: parse_datetime(row['Tempo de Conclusão']),
      commission_type: 'shopee'
    }
  end

  def normalize_status(status)
    case status&.downcase
    when 'concluído', 'completed'
      'completed'
    when 'pendente', 'pending'
      'pending'
    when 'cancelado', 'cancelled'
      'cancelled'
    else
      status&.downcase
    end
  end

  def parse_datetime(datetime_str)
    return nil if datetime_str.blank? || datetime_str == '--'
    
    begin
      DateTime.parse(datetime_str)
    rescue
      nil
    end
  end

  def parse_decimal(value)
    return 0 if value.blank?
    
    # Remove símbolos de moeda e converte para decimal
    cleaned_value = value.to_s.gsub(/[R$\s,]/, '').gsub(',', '.')
    BigDecimal(cleaned_value)
  rescue
    0
  end

  def parse_percentage(value)
    return 0 if value.blank?
    
    # Remove % e converte para decimal
    cleaned_value = value.to_s.gsub('%', '')
    BigDecimal(cleaned_value)
  rescue
    0
  end
end
