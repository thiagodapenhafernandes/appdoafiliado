require 'csv'

class ClicksAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_advanced_tracking_access, only: [:index]
  
  # Debug method execution
  before_action :log_action_execution

  def index
    # Verificar se estamos analisando dados de CSV carregado
    if params[:from_csv] == 'true' && (session[:csv_analytics_file_id] || params[:file_id])
      @from_csv = true
      process_csv_analytics_data
    else
      # Análise tradicional do banco de dados
      @from_csv = false
      process_database_analytics_data
    end
    
    # Garantir que as variáveis sempre tenham valores padrão
    @clicks_by_referrer ||= {}
    @clicks_by_region ||= {}
    @clicks_by_hour ||= {}
    @clicks_by_day ||= {}
    @total_clicks ||= 0
    @total_commission ||= 0
    @period_info ||= "Nenhum dado disponível"
    @peak_hour ||= nil
    
    respond_to do |format|
      format.html
      format.json { render json: analytics_data }
    end
  end

  def import_csv
  end
  
  def process_csv_upload
    unless current_user.can_access_advanced_tracking?
      redirect_to dashboard_path, alert: 'Analytics de cliques avançados estão disponíveis apenas nos planos Pro e Elite. Faça upgrade para acessar!'
      return
    end

    # Limpar arquivos temporários antigos
    cleanup_old_csv_files

    if params[:csv_file].blank?
      flash[:error] = 'Por favor, selecione um arquivo CSV.'
      redirect_to clicks_analytics_import_csv_path
      return
    end

    csv_file = params[:csv_file]
    
    # Verificar tipo de arquivo
    unless ['text/csv', 'application/csv', 'application/vnd.ms-excel'].include?(csv_file.content_type) || 
           csv_file.original_filename.end_with?('.csv')
      flash[:error] = 'Por favor, selecione um arquivo CSV válido.'
      redirect_to clicks_analytics_import_csv_path
      return
    end
    
    # Limitar tamanho do arquivo (50MB)
    if csv_file.size > 50.megabytes
      flash[:error] = 'Arquivo muito grande. O limite é de 50MB.'
      redirect_to clicks_analytics_import_csv_path
      return
    end
    
    begin
      # Ler arquivo CSV com tratamento de encoding
      csv_data = csv_file.read
      
      # Forçar encoding UTF-8 primeiro
      if csv_data.encoding != Encoding::UTF_8
        csv_data = csv_data.force_encoding('UTF-8')
      end
      
      # Se não for válido UTF-8, tentar ISO-8859-1
      unless csv_data.valid_encoding?
        csv_data = csv_data.force_encoding('ISO-8859-1').encode('UTF-8', invalid: :replace, undef: :replace)
      end
      
      # Remover BOM UTF-8 se presente (agora com string UTF-8 válida)
      csv_data = csv_data.sub(/\A\uFEFF/, '')
      
      valid_records = []
      
      CSV.parse(csv_data, headers: true, liberal_parsing: true) do |row|
        # Headers esperados do Shopee (português)
        click_id = row['ID dos Cliques']
        click_time_str = row['Tempo dos Cliques']
        commission = row['Comissão Estimada']
        region = row['Região'] || 'Desconhecido'
        
        next if click_id.blank? || click_time_str.blank?
        
        begin
          # Parse da data/hora no formato brasileiro: 2024-09-03 04:28:50
          click_time = Time.strptime(click_time_str, '%Y-%m-%d %H:%M:%S')
          
          # Extrair referrer do click_id ou definir como 'Shopee'
          referrer = 'Shopee'
          
          valid_records << {
            click_id: click_id,
            click_time: click_time,
            commission: commission.to_f,
            region: region,
            referrer: referrer,
            sub_id: '' # Shopee não tem sub_id específico
          }
        rescue => e
          Rails.logger.error "Erro ao processar linha: #{e.message}"
          next
        end
      end
      
      if valid_records.any?
        # Armazenar dados em arquivo temporário para evitar overflow da sessão
        temp_file_id = SecureRandom.uuid
        temp_file_path = Rails.root.join('tmp', "csv_analytics_#{temp_file_id}.json")
        File.write(temp_file_path, valid_records.to_json)
        
        # Armazenar apenas o ID do arquivo na sessão
        session[:csv_analytics_file_id] = temp_file_id
        session[:csv_analytics_uploaded_at] = Time.current
        
        flash[:success] = "#{valid_records.count} registros carregados com sucesso! Redirecionando para análise..."
        redirect_to clicks_analytics_path(from_csv: 'true', file_id: temp_file_id)
      else
        flash[:error] = 'Nenhum registro válido foi encontrado no arquivo.'
        redirect_to clicks_analytics_import_csv_path
      end
      
    rescue CSV::MalformedCSVError => e
      flash[:error] = "Erro no formato do arquivo CSV: #{e.message}"
      redirect_to clicks_analytics_import_csv_path
    rescue => e
      flash[:error] = "Erro ao processar arquivo: #{e.message}"
      redirect_to clicks_analytics_import_csv_path
    end
  end

  private

  def process_csv_analytics_data
    # Recuperar dados do arquivo temporário
    file_id = params[:file_id] || session[:csv_analytics_file_id]
    return unless file_id
    
    temp_file_path = Rails.root.join('tmp', "csv_analytics_#{file_id}.json")
    return unless File.exist?(temp_file_path)
    
    # Ler dados do arquivo
    @csv_data = JSON.parse(File.read(temp_file_path), symbolize_names: true)
    
    # Converter strings de data de volta para objetos Time
    @csv_data.each do |record|
      record[:click_time] = Time.parse(record[:click_time]) if record[:click_time].is_a?(String)
    end
    
    return unless @csv_data

    # Processar estatísticas
    @total_clicks = @csv_data.count
    @total_commission = @csv_data.sum { |record| record[:commission] }
    
    # Agrupar por região
    region_data = @csv_data.group_by { |record| record[:region] }
                           .transform_values(&:count)
    
    # Agrupar por referrer
    referrer_data = @csv_data.group_by { |record| record[:referrer] }
                             .transform_values(&:count)
    
    # Agrupar por hora
    hourly_data = @csv_data.group_by { |record| record[:click_time].hour }
                           .transform_values(&:count)
                           .sort.to_h
    
    # Agrupar por dia
    daily_data = @csv_data.group_by { |record| record[:click_time].to_date }
                          .transform_values(&:count)
                          .sort.to_h

    # Período dos dados
    dates = @csv_data.map { |record| record[:click_time].to_date }
    @period_start = dates.min
    @period_end = dates.max
    @period_info = get_data_period_info(@period_start, @period_end)

    # Preparar dados para os gráficos
    @referrer_chart_data = format_referrer_chart_data(referrer_data)
    @region_chart_data = format_region_chart_data(region_data)
    @hourly_chart_data = format_hourly_chart_data(hourly_data)
    @daily_chart_data = format_daily_chart_data(daily_data)

    # Horário de pico
    @peak_hour = find_peak_hour(hourly_data)
    
    # Variáveis compatíveis com a view existente
    @clicks_by_referrer = referrer_data
    @clicks_by_region = region_data
    @clicks_by_hour = hourly_data
    @clicks_by_day = daily_data
  end

  def process_database_analytics_data
    # Análise tradicional do banco de dados
    @clicks = current_user.website_clicks.includes(:device)
    
    # Filtros de data
    if params[:start_date].present? && params[:end_date].present?
      @clicks = @clicks.where(click_time: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
    else
      # Últimos 30 dias por padrão
      @clicks = @clicks.where(click_time: 30.days.ago..Time.current)
    end

    @total_clicks = @clicks.count
    
    # Estatísticas por região
    region_data = @clicks.group(:region).count
    
    # Estatísticas por referrer
    referrer_data = @clicks.group(:referrer).count
    
    # Estatísticas por hora
    hourly_data = @clicks.group_by_hour(:click_time).count
    
    # Estatísticas por dia
    daily_data = @clicks.group_by_day(:click_time).count

    # Período dos dados
    if @clicks.any?
      @period_start = @clicks.minimum(:click_time).to_date
      @period_end = @clicks.maximum(:click_time).to_date
    else
      @period_start = @period_end = Date.current
    end
    @period_info = get_data_period_info(@period_start, @period_end)

    # Preparar dados para os gráficos
    @referrer_chart_data = format_referrer_chart_data(referrer_data)
    @region_chart_data = format_region_chart_data(region_data)
    @hourly_chart_data = format_hourly_chart_data(hourly_data)
    @daily_chart_data = format_daily_chart_data(daily_data)

    # Horário de pico
    @peak_hour = find_peak_hour(hourly_data)
    
    # Variáveis compatíveis com a view existente
    @clicks_by_referrer = referrer_data
    @clicks_by_region = region_data
    @clicks_by_hour = hourly_data
    @clicks_by_day = daily_data
  end

  def get_data_period_info(start_date, end_date)
    days_diff = (end_date - start_date).to_i + 1
    
    if days_diff == 1
      "Dados de #{start_date.strftime('%d/%m/%Y')}"
    elsif days_diff <= 7
      "Dados de #{start_date.strftime('%d/%m')} a #{end_date.strftime('%d/%m/%Y')}"
    else
      "Dados de #{start_date.strftime('%d/%m/%Y')} a #{end_date.strftime('%d/%m/%Y')} (#{days_diff} dias)"
    end
  end

  def format_referrer_chart_data(data)
    return { labels: [], datasets: [] } if data.empty?
    
    labels = data.keys.map { |referrer| referrer.present? ? referrer : 'Direto' }
    values = data.values
    
    {
      labels: labels,
      datasets: [{
        data: values,
        backgroundColor: [
          '#FF6384',
          '#36A2EB',
          '#FFCE56',
          '#4BC0C0',
          '#9966FF',
          '#FF9F40'
        ],
        borderWidth: 1
      }]
    }
  end

  def format_region_chart_data(data)
    return { labels: [], datasets: [] } if data.empty?
    
    labels = data.keys.map { |region| region.present? ? region : 'Desconhecido' }
    values = data.values
    
    {
      labels: labels,
      datasets: [{
        data: values,
        backgroundColor: [
          '#FF6384',
          '#36A2EB',
          '#FFCE56',
          '#4BC0C0',
          '#9966FF',
          '#FF9F40'
        ],
        borderWidth: 1
      }]
    }
  end

  def format_hourly_chart_data(data)
    return { labels: [], datasets: [] } if data.empty?
    
    # Garantir que todas as horas (0-23) estejam representadas
    hours = (0..23).to_a
    values = hours.map { |hour| data[hour] || 0 }
    
    {
      labels: hours.map { |h| "#{h}:00" },
      datasets: [{
        label: 'Cliques por Hora',
        data: values,
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        tension: 0.1
      }]
    }
  end

  def format_daily_chart_data(data)
    return { labels: [], datasets: [] } if data.empty?
    
    sorted_data = data.map do |date, count|
      [date.strftime('%d/%m'), count]
    end.sort_by(&:first)
    
    {
      labels: sorted_data.map(&:first),
      datasets: [{
        label: 'Cliques por Dia',
        data: sorted_data.map(&:last),
        borderColor: 'rgb(54, 162, 235)',
        backgroundColor: 'rgba(54, 162, 235, 0.2)',
        tension: 0.1
      }]
    }
  end

  def find_peak_hour(hourly_data)
    return nil if hourly_data.empty?
    
    peak_hour = hourly_data.max_by { |hour, count| count }&.first
    peak_hour ? "#{peak_hour}:00" : nil
  end

  def analytics_data
    {
      total_clicks: @total_clicks || 0,
      total_commission: @total_commission || 0,
      period_info: @period_info,
      peak_hour: @peak_hour,
      referrer_data: @referrer_chart_data || [],
      region_data: @region_chart_data || [],
      hourly_data: @hourly_chart_data || [],
      daily_data: @daily_chart_data || [],
      from_csv: @from_csv || false
    }
  end

  def log_action_execution
    puts "🔥 ACTION EXECUTADA: #{action_name} - MÉTODO: #{request.method}"
    Rails.logger.info "🔥 ACTION EXECUTADA: #{action_name} - MÉTODO: #{request.method}"
  end

  def check_advanced_tracking_access
    puts "=== VERIFICAÇÃO DE ACESSO ==="
    puts "User ID: #{current_user.id}"
    puts "On trial?: #{current_user.on_trial?}"
    puts "Trial ends at: #{current_user.trial_ends_at}"
    puts "Current plan: #{current_user.current_plan&.name}"
    puts "Can access advanced tracking?: #{current_user.can_access_advanced_tracking?}"
    puts "=========================="
    
    unless current_user.can_access_advanced_tracking?
      puts "ACESSO NEGADO - REDIRECIONANDO"
      redirect_to dashboard_path, alert: 'Analytics de cliques avançados estão disponíveis apenas nos planos Pro e Elite. Faça upgrade para acessar!'
    else
      puts "ACESSO LIBERADO"
    end
  end
  
  def cleanup_old_csv_files
    # Limpar arquivos temporários mais antigos que 2 horas
    Dir.glob(Rails.root.join('tmp', 'csv_analytics_*.json')).each do |file_path|
      if File.mtime(file_path) < 2.hours.ago
        File.delete(file_path)
      end
    end
  end
end
