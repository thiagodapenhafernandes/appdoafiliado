class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_analytics_access, only: [:performance, :conversion]
  before_action :check_pdf_export_access, only: [:export_pdf]
  
  def index
    # Analisar todos os dados importados (CSV + API) - sem filtro de período
    @commissions = current_user.all_commissions_unified.where.not(order_status: 'cancelled')
    
    # Métricas principais - dados completos (CSV + API)
    @total_commissions = @commissions.sum(:affiliate_commission) || 0
    @total_sales = @commissions.sum(:purchase_value) || 0
    @total_orders = @commissions.count
    @average_ticket = @total_orders > 0 ? (@total_sales / @total_orders) : 0
    @conversion_rate = calculate_conversion_rate
    
    # Métricas por fonte de dados
    @csv_commissions = @commissions.from_csv.sum(:affiliate_commission) || 0
    @api_commissions = @commissions.from_api.sum(:affiliate_commission) || 0
    @csv_orders = @commissions.from_csv.count
    @api_orders = @commissions.from_api.count
    
    # Período dos dados (automático baseado nos dados importados)
    @date_range_info = get_data_period_info
    
    # Dados para gráficos - todos os dados (CSV + API)
    @daily_commissions = daily_commission_chart
    @channel_performance = channel_performance_chart_with_details
    @category_performance = category_performance_with_details
    @top_products = top_products_with_details
    @performance_by_subid = performance_by_subid_with_details
    
    # Análise de Pedidos Diretos vs Indiretos
    @direct_indirect_analysis = calculate_direct_indirect_analysis
    
    # Status da integração Shopee
    @shopee_integration_status = get_shopee_integration_status
  end

  def performance
    # Analisar todos os dados importados do CSV (sem filtro de período)
    @commissions = current_user.commissions.where.not(order_status: 'cancelled')
    
    @performance_by_channel = performance_by_channel
    @performance_by_category = performance_by_category
    @performance_by_subid = performance_by_subid
    @daily_performance = daily_performance_evolution
    @total_commissions = @commissions.sum(:affiliate_commission)
  end

  def conversion
    # Analisar todos os dados importados do CSV (sem filtro de período)
    @commissions = current_user.commissions.where.not(order_status: 'cancelled')
    
    @conversion_funnel = conversion_funnel_data
    @roi_analysis = roi_analysis_data
    @attribution_analysis = attribution_analysis_data
  end

  def import_csv
    if request.post? && params[:csv_file].present?
      file = params[:csv_file]
      
      # Salvar arquivo temporariamente
      temp_file = Rails.root.join('tmp', "import_#{current_user.id}_#{Time.current.to_i}.csv")
      File.open(temp_file, 'wb') { |f| f.write(file.read) }
      
      # Processar dados de gastos com ads se fornecidos
      total_investment = params[:total_investment].to_f if params[:total_investment].present?
      subid_data = params[:subid_data] || {}
      
      # Importar dados
      import_service = CsvImportService.new(current_user, temp_file)
      
      if import_service.import
        result = import_service.import_commissions
        
        # Processar gastos com ads se fornecidos
        if (subid_data.present? && subid_data.keys.any?) || (total_investment && total_investment > 0)
          save_ad_spend_data(subid_data, total_investment)
        end
        
        flash[:notice] = "Importação realizada com sucesso! #{result[:imported]} registros criados, #{result[:updated]} atualizados."
        redirect_to analytics_path
      else
        flash[:alert] = "Erro na importação: #{import_service.errors.join(', ')}"
      end
      
      # Limpar arquivo temporário
      File.delete(temp_file) if File.exist?(temp_file)
    end
  end

  def export_pdf
    begin
      pdf_service = AnalyticsPdfService.new(current_user)
      pdf_content = pdf_service.generate_report.render
      
      send_data pdf_content,
                filename: "analytics_report_#{Date.current.strftime('%Y%m%d')}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    rescue => e
      Rails.logger.error "Erro ao gerar PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      flash[:error] = "Erro ao gerar relatório em PDF: #{e.message}"
      redirect_to analytics_path
    end
  end

  def update_ad_spend
    # Verificar se o usuário tem acesso aos analytics
    return render json: { success: false, error: 'Access denied' }, status: 403 unless current_user.can_access_advanced_analytics?
    
    subid = params[:subid] == 'Não informado' ? nil : params[:subid]
    ad_spend = params[:ad_spend].to_f

    # Buscar ou criar o registro de gasto com ads para este SubID
    ad_spend_record = current_user.subid_ad_spends.find_or_initialize_by(subid: subid)
    ad_spend_record.ad_spend = ad_spend
    ad_spend_record.period_start = Date.current.beginning_of_month
    ad_spend_record.period_end = Date.current.end_of_month

    if ad_spend_record.save
      # Recalcular métricas para resposta
      @commissions = current_user.all_commissions_unified.where.not(order_status: 'cancelled')
      scope = subid.present? ? @commissions.where(sub_id1: subid) : @commissions.where(sub_id1: [nil, ''])
      
      commission_value = scope.sum(:affiliate_commission) || 0
      orders_count = scope.count
      roi = ad_spend > 0 ? ((commission_value.to_f - ad_spend) / ad_spend * 100) : 0
      cpa = orders_count > 0 && ad_spend > 0 ? (ad_spend / orders_count) : 0

      render json: {
        success: true,
        ad_spend: ad_spend,
        roi: roi,
        cpa: cpa,
        formatted_ad_spend: ActionController::Base.helpers.number_with_precision(ad_spend, precision: 2, delimiter: '.', separator: ','),
        formatted_roi: ActionController::Base.helpers.number_with_precision(roi, precision: 1),
        formatted_cpa: ActionController::Base.helpers.number_with_precision(cpa, precision: 2, delimiter: '.', separator: ',')
      }
    else
      render json: { success: false, errors: ad_spend_record.errors.full_messages }, status: 422
    end
  end

  private

  def calculate_date_range(range)
    case range
    when '7_days'
      [7.days.ago.beginning_of_day, Time.current.end_of_day]
    when '30_days'
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    when '90_days'
      [90.days.ago.beginning_of_day, Time.current.end_of_day]
    when 'this_month'
      [Time.current.beginning_of_month, Time.current.end_of_month]
    when 'last_month'
      [1.month.ago.beginning_of_month, 1.month.ago.end_of_month]
    else
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    end
  end

  def calculate_conversion_rate
    total_clicks = current_user.links.sum(:clicks_count)
    return 0 if total_clicks.zero?
    
    (@total_orders.to_f / total_clicks * 100).round(2)
  end

  def get_data_period_info
    return { start_date: nil, end_date: nil, total_days: 0 } if @commissions.empty?
    
    start_date = @commissions.minimum(:order_date)
    end_date = @commissions.maximum(:order_date)
    total_days = (end_date - start_date).to_i + 1
    
    {
      start_date: start_date,
      end_date: end_date,
      total_days: total_days,
      formatted_range: "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}"
    }
  end

  def daily_commission_chart
    @commissions.group_by_day(:order_date)
                .sum(:affiliate_commission)
  end

  def channel_performance_chart
    @commissions.group(:channel)
                .sum(:affiliate_commission)
                .reject { |k, _| k.blank? }
  end

  def category_performance_chart
    @commissions.group(:category_l1)
                .sum(:affiliate_commission)
                .sort_by { |_, v| -v }
                .first(10)
                .to_h
  end

  def top_products_chart
    @commissions.group(:item_name)
                .sum(:affiliate_commission)
                .sort_by { |_, v| -v }
                .first(10)
                .to_h
  end

  def performance_by_channel
    @commissions.group(:channel)
                .select('channel, 
                         COUNT(*) as orders_count,
                         SUM(affiliate_commission) as total_commission,
                         SUM(purchase_value) as total_sales,
                         AVG(affiliate_commission) as avg_commission')
                .order('total_commission DESC')
  end

  def performance_by_category
    @commissions.group(:category_l1)
                .select('category_l1,
                         COUNT(*) as orders_count,
                         SUM(affiliate_commission) as total_commission,
                         SUM(purchase_value) as total_sales')
                .order('total_commission DESC')
  end

  def performance_by_subid
    # Incluir TODOS os registros, inclusive os sem SubID
    results = @commissions.group(:sub_id1)
                          .select('sub_id1,
                                   COUNT(*) as orders_count,
                                   SUM(affiliate_commission) as total_commission,
                                   SUM(purchase_value) as total_sales')
                          .order('total_commission DESC')
                          .limit(20)
    
    # Converter para hash com as chaves esperadas pela view
    results.map do |result|
      {
        subid: result.sub_id1 || 'N/A',
        commissions: result.total_commission || 0,
        sales: result.total_sales || 0,
        orders: result.orders_count || 0,
        conversion_rate: nil # Não temos dados de cliques por SubID ainda
      }
    end
  end

  def conversion_funnel_data
    total_clicks = current_user.links.sum(:clicks_count)
    total_orders = @commissions.count
    completed_orders = @commissions.where(order_status: 'completed').count
    
    {
      clicks: total_clicks,
      orders: total_orders,
      completed: completed_orders,
      click_to_order: total_clicks > 0 ? (total_orders.to_f / total_clicks * 100).round(2) : 0,
      order_to_completion: total_orders > 0 ? (completed_orders.to_f / total_orders * 100).round(2) : 0
    }
  end

  def roi_analysis_data
    @commissions.group(:channel)
                .select('channel,
                         SUM(affiliate_commission) as revenue,
                         COUNT(*) as orders,
                         AVG(affiliate_commission) as avg_commission,
                         SUM(purchase_value) as total_sales')
  end

  def attribution_analysis_data
    @commissions.group(:attribution_type)
                .select('attribution_type,
                         COUNT(*) as orders_count,
                         SUM(affiliate_commission) as total_commission')
                .order('total_commission DESC')
  end

  def channel_performance_chart_with_details
    # Abordagem mais simples - usar agregações básicas
    channels = @commissions.distinct.pluck(:channel).compact
    channels << nil if @commissions.where(channel: [nil, '']).exists? # Incluir registros sem channel
    
    result = {}
    channels.each do |channel|
      scope = channel.present? ? @commissions.where(channel: channel) : @commissions.where(channel: [nil, ''])
      
      commission_total = scope.sum(:affiliate_commission) || 0
      orders_count = scope.count
      sales_total = scope.sum(:purchase_value) || 0
      
      channel_name = channel.present? ? channel : 'Não informado'
      result[channel_name] = {
        commission: commission_total.to_f,
        orders: orders_count,
        sales: sales_total.to_f
      }
    end
    result
  end

  def category_performance_with_details
    # Abordagem mais simples - usar agregações básicas
    categories = @commissions.distinct.pluck(:category_l1).compact
    categories << nil if @commissions.where(category_l1: [nil, '']).exists?
    
    total_commission = @total_commissions
    result = {}
    
    categories.each do |category|
      scope = category.present? ? @commissions.where(category_l1: category) : @commissions.where(category_l1: [nil, ''])
      
      commission_value = scope.sum(:affiliate_commission) || 0
      orders_count = scope.count
      sales_value = scope.sum(:purchase_value) || 0
      percentage = total_commission > 0 ? (commission_value.to_f / total_commission * 100) : 0
      
      category_name = category.present? ? category : 'Categoria não informada'
      result[category_name] = {
        commission: commission_value.to_f,
        orders: orders_count,
        sales: sales_value.to_f,
        percentage: percentage
      }
    end
    result
  end

  def top_products_with_details
    # Abordagem mais simples - buscar top produtos ordenados
    products_data = @commissions.group(:item_name, :item_id)
                                .sum(:affiliate_commission)
                                .sort_by { |_, commission| -commission }
                                .first(20)
    
    total_commission = @total_commissions
    result = []
    
    products_data.each do |product_key, commission_value|
      item_name, item_id = product_key
      scope = @commissions.where(item_name: item_name, item_id: item_id)
      
      orders_count = scope.count
      sales_value = scope.sum(:purchase_value) || 0
      percentage = total_commission > 0 ? (commission_value.to_f / total_commission * 100) : 0
      
      result << {
        name: item_name.present? ? item_name : 'Produto não informado',
        product_id: item_id,
        commission: commission_value.to_f,
        orders: orders_count,
        sales: sales_value.to_f,
        percentage: percentage
      }
    end
    result
  end

  def performance_by_subid_with_details
    # Abordagem mais simples - buscar SubIDs únicos
    subids = @commissions.distinct.pluck(:sub_id1)
    subids = subids.compact + [nil] if @commissions.where(sub_id1: [nil, '']).exists?
    
    total_commission = @commissions.sum(:affiliate_commission)
    result = {}
    
    # Ordenar subids por comissão total (limitando a 50)
    subid_commissions = subids.map do |subid|
      scope = subid.present? ? @commissions.where(sub_id1: subid) : @commissions.where(sub_id1: [nil, ''])
      commission_total = scope.sum(:affiliate_commission) || 0
      [subid, commission_total]
    end.sort_by { |_, commission| -commission }.first(50)
    
    subid_commissions.each do |subid, _|
      scope = subid.present? ? @commissions.where(sub_id1: subid) : @commissions.where(sub_id1: [nil, ''])
      
      commission_value = scope.sum(:affiliate_commission) || 0
      orders_count = scope.count
      sales_value = scope.sum(:purchase_value) || 0
      percentage = total_commission > 0 ? (commission_value.to_f / total_commission * 100) : 0
      
      # Buscar gastos reais com ads para este SubID
      real_ad_spend = current_user.subid_ad_spends.for_subid(subid).sum(:ad_spend)
      ad_spend = real_ad_spend > 0 ? real_ad_spend : 0
      roi = ad_spend > 0 ? ((commission_value.to_f - ad_spend) / ad_spend * 100) : 0
      cpa = orders_count > 0 && ad_spend > 0 ? (ad_spend / orders_count) : 0
      
      subid_name = subid.present? ? subid : 'Não informado'
      result[subid_name] = {
        commission: commission_value.to_f,
        orders: orders_count,
        sales: sales_value.to_f,
        percentage: percentage,
        ad_spend: ad_spend,
        roi: roi,
        cpa: cpa
      }
    end
    result
  end

  # Método para salvar dados de gastos com ads
  def save_ad_spend_data(subid_data, total_investment = nil)
    # Determinar período baseado nos dados mais recentes das comissões
    commissions = current_user.commissions.where.not(order_status: 'cancelled')
    return if commissions.empty?
    
    period_start = commissions.minimum(:order_date)
    period_end = commissions.maximum(:order_date)
    
    # Limpar dados antigos para este período (permitir atualização)
    current_user.subid_ad_spends.where(
      period_start: period_start,
      period_end: period_end
    ).destroy_all
    
    # Salvar dados de cada SubID
    subid_data.each do |key, data|
      next if data['subid'].blank? || data['ad_spend'].blank?
      
      current_user.subid_ad_spends.create!(
        subid: data['subid'],
        ad_spend: data['ad_spend'].to_f,
        total_investment: total_investment,
        period_start: period_start,
        period_end: period_end
      )
    end
  end

  def check_analytics_access
    unless current_user.can_access_advanced_analytics?
      redirect_to plans_path, alert: 'Análises avançadas estão disponíveis apenas nos planos Pro e Elite. Faça upgrade para acessar!'
    end
  end

  def check_pdf_export_access
    unless current_user.can_export_pdf?
      redirect_to plans_path, alert: 'Exportação de relatórios em PDF está disponível apenas nos planos Pro e Elite. Faça upgrade para acessar!'
    end
  end

  # Métodos para análise de performance
  def performance_by_channel
    # Usar dados reais dos canais baseado nas comissões existentes
    return [] if @commissions.empty?
    
    # Agrupar por canal real dos dados
    channel_data = @commissions.group(:channel)
                               .sum(:affiliate_commission)
    
    channels = []
    channel_data.each do |channel, total_commission|
      channel_commissions = @commissions.where(channel: channel)
      sales = channel_commissions.sum(:purchase_value) || 0
      orders = channel_commissions.count
      avg_ticket = orders > 0 ? (sales / orders) : 0
      
      # Calcular ROI básico (para demonstração, assume-se 0 de investimento inicial)
      # Em um caso real, você teria dados de investimento por canal
      roi = 0.0 # Placeholder - seria calculado com base em dados de investimento reais
      
      channels << {
        channel: channel || 'Não informado',
        commissions: total_commission.to_f,
        sales: sales.to_f,
        orders: orders,
        avg_ticket: avg_ticket.to_f,
        roi: roi
      }
    end
    
    channels.sort_by { |c| -c[:commissions] }
  end

  def performance_by_category
    # Usar dados reais das categorias se disponíveis
    return [] if @commissions.empty?
    
    # Agrupar por categoria real dos dados (usando category_l1, category_l2 ou category_l3)
    category_data = {}
    
    # Tentar agrupar por categoria_l1 primeiro, depois l2, depois l3
    [:category_l1, :category_l2, :category_l3].each do |category_field|
      if @commissions.where.not(category_field => [nil, '']).exists?
        category_data = @commissions.where.not(category_field => [nil, ''])
                                   .group(category_field)
                                   .sum(:affiliate_commission)
        break unless category_data.empty?
      end
    end
    
    # Se não há categorias nos dados, retornar vazio
    return [] if category_data.empty?
    
    result = []
    category_data.each do |category, total_commission|
      category_commissions = @commissions.where(
        'category_l1 = ? OR category_l2 = ? OR category_l3 = ?', 
        category, category, category
      )
      
      sales = category_commissions.sum(:purchase_value) || 0
      orders = category_commissions.count
      avg_ticket = orders > 0 ? (sales / orders) : 0
      
      result << {
        category: category || 'Não informado',
        commissions: total_commission.to_f,
        sales: sales.to_f,
        orders: orders,
        avg_ticket: avg_ticket.to_f
      }
    end
    
    result.sort_by { |c| -c[:commissions] }.first(10)
  end

  def performance_by_subid
    # Buscar SubIDs únicos e calcular métricas
    subids = @commissions.distinct.pluck(:sub_id1)
    subids = subids.compact + [nil] if @commissions.where(sub_id1: [nil, '']).exists?
    
    # Ordenar subids por comissão total (limitando a 20)
    subid_commissions = subids.map do |subid|
      scope = subid.present? ? @commissions.where(sub_id1: subid) : @commissions.where(sub_id1: [nil, ''])
      commission_total = scope.sum(:affiliate_commission) || 0
      [subid, commission_total]
    end.sort_by { |_, commission| -commission }.first(20)
    
    result = []
    subid_commissions.each do |subid, _|
      scope = subid.present? ? @commissions.where(sub_id1: subid) : @commissions.where(sub_id1: [nil, ''])
      
      commission_value = scope.sum(:affiliate_commission) || 0
      orders_count = scope.count
      sales_value = scope.sum(:purchase_value) || 0
      
      # Calcular taxa de conversão baseada em dados reais se disponível
      # Por enquanto, apenas incluir métricas básicas sem conversão simulada
      
      subid_name = subid.present? ? subid : 'Não informado'
      result << {
        subid: subid_name,
        commissions: commission_value.to_f,
        sales: sales_value.to_f,
        orders: orders_count
      }
    end
    
    result
  end

  def daily_performance_evolution
    # Agrupar comissões por data usando ActiveRecord
    daily_data = @commissions.group_by_day(:order_date)
                            .sum(:affiliate_commission)
    
    result = []
    daily_data.each do |date, commission_total|
      daily_scope = @commissions.where(order_date: date.beginning_of_day..date.end_of_day)
      orders_count = daily_scope.count
      sales_value = daily_scope.sum(:purchase_value) || 0
      avg_ticket = orders_count > 0 ? (sales_value.to_f / orders_count) : 0
      
      result << {
        date: date,
        commissions: commission_total.to_f,
        orders: orders_count,
        sales: sales_value.to_f,
        avg_ticket: avg_ticket
      }
    end
    
    result.sort_by { |row| row[:date] }
  end

  # Métodos para análise de conversão
  def conversion_funnel_data
    # Usar dados reais das tabelas
    total_clicks = current_user.links.sum(:clicks_count) || 0
    total_conversions = @commissions.count
    
    return [] if total_clicks == 0
    
    [
      {
        name: 'Cliques',
        icon: '👆',
        count: total_clicks,
        percentage: 100.0,
        conversion_rate: nil
      },
      {
        name: 'Conversões',
        icon: '🎯',
        count: total_conversions,
        percentage: total_conversions > 0 ? (total_conversions.to_f / total_clicks * 100) : 0,
        conversion_rate: total_conversions > 0 ? (total_conversions.to_f / total_clicks * 100) : 0
      }
    ]
  end

  def roi_analysis_data
    total_commissions = @commissions.sum(:affiliate_commission)
    total_invested = current_user.subid_ad_spends.sum(:ad_spend) if current_user.respond_to?(:subid_ad_spends)
    total_invested ||= 0
    
    total_return = total_commissions
    overall_roi = total_invested > 0 ? ((total_return - total_invested) / total_invested * 100) : 0
    
    {
      overall_roi: overall_roi,
      total_invested: total_invested,
      total_return: total_return,
      by_channel: []
    }
  end

  def attribution_analysis_data
    return {} if @commissions.empty?
    
    # Retornar dados vazios pois não temos dados de atribuição reais
    {
      first_click: [],
      last_click: [],
      customer_journeys: [],
      top_discovery_channel: nil,
      top_conversion_channel: nil,
      avg_time_to_conversion: 0,
      avg_touchpoints: 0
    }
  end

  def calculate_direct_indirect_analysis
    # Pedidos Diretos: "Pedido na mesma loja"
    direct_orders = @commissions.where(attribution_type: "Pedido na mesma loja")
    # Pedidos Indiretos: "Pedido em loja diferente"  
    indirect_orders = @commissions.where(attribution_type: "Pedido em loja diferente")
    
    direct_count = direct_orders.count
    indirect_count = indirect_orders.count
    total_count = direct_count + indirect_count
    
    direct_commission = direct_orders.sum(:affiliate_commission) || 0
    indirect_commission = indirect_orders.sum(:affiliate_commission) || 0
    total_commission = direct_commission + indirect_commission
    
    direct_percentage = total_commission > 0 ? (direct_commission / total_commission * 100) : 0
    indirect_percentage = total_commission > 0 ? (indirect_commission / total_commission * 100) : 0
    
    {
      direct: {
        orders: direct_count,
        commission: direct_commission,
        percentage: direct_percentage
      },
      indirect: {
        orders: indirect_count, 
        commission: indirect_commission,
        percentage: indirect_percentage
      },
      total: {
        orders: total_count,
        commission: total_commission
      }
    }
  end

  def get_shopee_integration_status
    integration = current_user.shopee_affiliate_integration
    
    return { enabled: false } unless integration
    
    {
      enabled: true,
      active: integration.active?,
      connected: integration.connected?,
      last_sync: integration.last_sync_at,
      sync_count: integration.sync_count,
      has_error: integration.last_error.present?,
      error_message: integration.last_error,
      total_api_conversions: current_user.affiliate_conversions.count,
      api_commissions_amount: current_user.api_commissions.sum(:affiliate_commission)
    }
  end
end
