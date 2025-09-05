class AnalyticsPdfService
  require 'prawn'
  require 'prawn/table'

  def initialize(user)
    @user = user
    @commissions = user.commissions.where.not(order_status: 'cancelled')
  end

  def generate_report
    Prawn::Document.new(page_size: 'A4', margin: 40) do |pdf|
      # Configurar fonte
      pdf.font_families.update(
        'Helvetica' => {
          normal: Rails.root.join('vendor', 'fonts', 'Helvetica.ttf').to_s
        }
      )
      pdf.font 'Helvetica'

      # Cabeçalho
      add_header(pdf)
      
      # Resumo geral
      add_summary(pdf)
      
      # Análise por SubID
      add_subid_analysis(pdf)
      
      # Análise por canal
      add_channel_analysis(pdf)
      
      # Produtos top
      add_top_products(pdf)
      
      # Rodapé
      add_footer(pdf)
    end
  end

  private

  def add_header(pdf)
    pdf.text "Relatório de Analytics - LinkFlow", size: 20, style: :bold, align: :center
    pdf.text "Período: #{@commissions.minimum(:order_date)&.strftime('%d/%m/%Y')} a #{@commissions.maximum(:order_date)&.strftime('%d/%m/%Y')}", 
             size: 12, align: :center, color: '666666'
    pdf.text "Gerado em: #{Date.current.strftime('%d/%m/%Y às %H:%M')}", size: 10, align: :center, color: '999999'
    pdf.move_down 30
  end

  def add_summary(pdf)
    total_commission = @commissions.sum(:affiliate_commission)
    total_sales = @commissions.sum(:purchase_value)
    total_orders = @commissions.count
    
    pdf.text "📊 Resumo Geral", size: 16, style: :bold
    pdf.move_down 10
    
    summary_data = [
      ["Métrica", "Valor"],
      ["Total de Comissões", "R$ #{number_format(total_commission)}"],
      ["Total de Vendas", "R$ #{number_format(total_sales)}"],
      ["Total de Pedidos", "#{total_orders}"],
      ["Comissão Média por Pedido", "R$ #{number_format(total_orders > 0 ? total_commission / total_orders : 0)}"],
      ["Ticket Médio", "R$ #{number_format(total_orders > 0 ? total_sales / total_orders : 0)}"]
    ]
    
    pdf.table summary_data, 
              header: true,
              width: pdf.bounds.width,
              cell_style: { size: 10, padding: 8 },
              header_color: 'E5E7EB'
    
    pdf.move_down 20
  end

  def add_subid_analysis(pdf)
    pdf.text "🎯 Análise por SubID", size: 16, style: :bold
    pdf.move_down 10
    
    subid_data = get_subid_performance
    
    if subid_data.any?
      table_data = [["SubID", "Comissões", "Vendas", "Pedidos", "Gasto Ads", "ROI"]]
      
      subid_data.each do |subid, data|
        table_data << [
          subid.to_s.truncate(20),
          "R$ #{number_format(data[:commission])}",
          "R$ #{number_format(data[:sales])}",
          data[:orders].to_s,
          "R$ #{number_format(data[:ad_spend])}",
          "#{data[:roi].round(1)}%"
        ]
      end
      
      pdf.table table_data,
                header: true,
                width: pdf.bounds.width,
                cell_style: { size: 9, padding: 6 },
                header_color: 'E5E7EB'
    else
      pdf.text "Nenhum dado de SubID encontrado.", color: '666666'
    end
    
    pdf.move_down 20
  end

  def add_channel_analysis(pdf)
    pdf.text "📡 Análise por Canal", size: 16, style: :bold
    pdf.move_down 10
    
    channel_data = @commissions.group(:channel)
                               .select('channel, COUNT(*) as orders_count, SUM(affiliate_commission) as total_commission, SUM(purchase_value) as total_sales')
                               .order('total_commission DESC')
    
    if channel_data.any?
      table_data = [["Canal", "Comissões", "Vendas", "Pedidos"]]
      
      channel_data.each do |row|
        table_data << [
          (row.channel || 'Não informado').truncate(30),
          "R$ #{number_format(row.total_commission)}",
          "R$ #{number_format(row.total_sales)}",
          row.orders_count.to_s
        ]
      end
      
      pdf.table table_data,
                header: true,
                width: pdf.bounds.width,
                cell_style: { size: 9, padding: 6 },
                header_color: 'E5E7EB'
    else
      pdf.text "Nenhum dado de canal encontrado.", color: '666666'
    end
    
    pdf.move_down 20
  end

  def add_top_products(pdf)
    pdf.text "🏆 Top 10 Produtos", size: 16, style: :bold
    pdf.move_down 10
    
    products_data = @commissions.group(:item_name, :item_id)
                                .select('item_name, item_id, COUNT(*) as orders_count, SUM(affiliate_commission) as total_commission')
                                .order('total_commission DESC')
                                .limit(10)
    
    if products_data.any?
      table_data = [["Produto", "Comissões", "Pedidos"]]
      
      products_data.each do |row|
        table_data << [
          (row.item_name || 'Produto sem nome').truncate(40),
          "R$ #{number_format(row.total_commission)}",
          row.orders_count.to_s
        ]
      end
      
      pdf.table table_data,
                header: true,
                width: pdf.bounds.width,
                cell_style: { size: 9, padding: 6 },
                header_color: 'E5E7EB'
    else
      pdf.text "Nenhum dado de produto encontrado.", color: '666666'
    end
  end

  def add_footer(pdf)
    pdf.move_down 30
    pdf.text "Relatório gerado automaticamente pelo LinkFlow", 
             size: 8, align: :center, color: '999999'
    pdf.text "www.linkflow.com", size: 8, align: :center, color: '999999'
  end

  def get_subid_performance
    data = @commissions.select(
      'sub_id1',
      'COUNT(*) as orders_count',
      'SUM(affiliate_commission) as total_commission',
      'SUM(purchase_value) as total_sales'
    ).group(:sub_id1).order('total_commission DESC').limit(10)
    
    result = {}
    data.each do |row|
      subid = row.sub_id1.present? ? row.sub_id1 : 'Não informado'
      
      # Buscar gastos reais com ads
      ad_spend = @user.subid_ad_spends.for_subid(row.sub_id1).sum(:ad_spend)
      roi = ad_spend > 0 ? ((row.total_commission.to_f - ad_spend) / ad_spend * 100) : 0
      
      result[subid] = {
        commission: row.total_commission.to_f,
        orders: row.orders_count,
        sales: row.total_sales.to_f,
        ad_spend: ad_spend,
        roi: roi
      }
    end
    result
  end

  def number_format(number)
    sprintf('%.2f', number).gsub('.', ',')
  end
end
