## Não precisa mais de will_paginate/array, pois só usaremos ActiveRecord
require 'csv'

class ClicksAnalyticsController < ApplicationController

  # Listar todas as importações de cliques
  def imports
    @imports = WebsiteClickImport.order(created_at: :desc).includes(:website_clicks)
  end

  # Deletar uma importação e todos os cliques associados
  def delete_import
    import = WebsiteClickImport.find(params[:id])
    count = import.website_clicks.count
    import.website_clicks.destroy_all
    import.destroy
    flash[:success] = "Importação e #{count} cliques removidos com sucesso."
    redirect_to clicks_analytics_imports_path
  end
  # Importar e persistir cliques do CSV no banco
  def persist_csv_to_db
    file_id = params[:file_id] || session[:csv_analytics_file_id]
    return redirect_to clicks_analytics_path, alert: 'Arquivo não encontrado.' unless file_id
    temp_file_path = Rails.root.join('tmp', "csv_analytics_#{file_id}.json")
    return redirect_to clicks_analytics_path, alert: 'Arquivo não encontrado.' unless File.exist?(temp_file_path)
    # Salvar arquivo temporário como CSV para o serviço
    csv_temp = Rails.root.join('tmp', "csv_import_#{file_id}.csv")
    require 'json'
    require 'csv'
    json_data = JSON.parse(File.read(temp_file_path))
    headers = json_data.first&.keys || []
    CSV.open(csv_temp, 'w', write_headers: true, headers: headers) do |csv|
      json_data.each { |row| csv << row.values }
    end
    service = WebsiteClickImportService.new(current_user, csv_temp, "import_#{file_id}.csv")
    count = service.import!
    File.delete(csv_temp) if File.exist?(csv_temp)
    flash[:success] = "#{count} cliques importados e salvos no banco com sucesso!"
    redirect_to clicks_analytics_imports_path
  end
  # Deleta cliques por período
  def destroy_by_period
    if params[:start_date].present? && params[:end_date].present?
      WebsiteClick.delete_by_period(current_user, params[:start_date].to_date, params[:end_date].to_date)
      flash[:success] = "Cliques do período #{params[:start_date]} a #{params[:end_date]} deletados com sucesso."
    else
      flash[:error] = "Informe a data inicial e final para deletar por período."
    end
    redirect_to clicks_analytics_path
  end

  # Deleta todos os cliques do usuário
  def destroy_all
    WebsiteClick.delete_all_for_user(current_user)
    flash[:success] = "Todos os cliques foram deletados com sucesso."
    redirect_to clicks_analytics_path
  end
  before_action :authenticate_user!
  # Debug method execution removido (não existe mais o método)

  def index
    # Filtros simples direto no banco
    @clicks = current_user.website_clicks
    if params[:start_date].present? && params[:end_date].present?
      @clicks = @clicks.where(click_time: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
    end
    if params[:sub_id].present?
      @clicks = @clicks.where('sub_id ILIKE ?', "%#{params[:sub_id]}%")
    end
    if params[:click_id].present?
      @clicks = @clicks.where('click_id ILIKE ?', "%#{params[:click_id]}%")
    end
    if params[:region].present?
      @clicks = @clicks.where('region ILIKE ?', "%#{params[:region]}%")
    end
    if params[:referrer].present?
      @clicks = @clicks.where('referrer ILIKE ?', "%#{params[:referrer]}%")
    end
    @clicks = @clicks.order(click_time: :desc).paginate(page: params[:page], per_page: 10)

    # Agregações para gráficos e tabelas
    @clicks_by_sub_id = @clicks.group(:sub_id).count
    region_data = @clicks.group(:region).count
    referrer_data = @clicks.group(:referrer).count
    hourly_data = @clicks.group_by_hour(:click_time).count rescue {}
    daily_data = @clicks.group_by_day(:click_time).count rescue {}

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

    respond_to do |format|
      format.html
      format.json { render json: @clicks }
    end
  end

  def import_csv
  end
  
  def process_csv_upload
    unless current_user.can_access_advanced_tracking?
      redirect_to dashboard_path, alert: 'Analytics de cliques avançados estão disponíveis apenas nos planos Pro e Elite. Faça upgrade para acessar!'
      return
    end

  # Limpeza de arquivos temporários removida (não é mais necessária)

    if params[:csv_file].blank?
      flash[:error] = 'Por favor, selecione um arquivo CSV.'
      redirect_to clicks_analytics_import_csv_path
      return
    end
    csv_file = params[:csv_file]
    unless ['text/csv', 'application/csv', 'application/vnd.ms-excel'].include?(csv_file.content_type) || csv_file.original_filename.end_with?('.csv')
      flash[:error] = 'Por favor, selecione um arquivo CSV válido.'
      redirect_to clicks_analytics_import_csv_path
      return
    end
    if csv_file.size > 50.megabytes
      flash[:error] = 'Arquivo muito grande. O limite é de 50MB.'
      redirect_to clicks_analytics_import_csv_path
      return
    end
    begin
      csv_data = csv_file.read
      if csv_data.encoding != Encoding::UTF_8
        csv_data = csv_data.force_encoding('UTF-8')
      end
      unless csv_data.valid_encoding?
        csv_data = csv_data.force_encoding('ISO-8859-1').encode('UTF-8', invalid: :replace, undef: :replace)
      end
      csv_data = csv_data.sub(/\A\uFEFF/, '')
      valid_records = []
      CSV.parse(csv_data, headers: true, liberal_parsing: true) do |row|
        click_id = row['ID dos Cliques']
        click_time_str = row['Tempo dos Cliques']
        # commission = row['Comissão Estimada'] # Não existe mais no modelo
        region = row['Região dos Cliques'] || row['Região'] || 'Desconhecido'
        sub_id = row['Sub_id'] || row['SubID'] || ''
        referrer = row['Referenciador'] || row['Referrer'] || ''
        next if click_id.blank? || click_time_str.blank?
        begin
          click_time = Time.strptime(click_time_str, '%Y-%m-%d %H:%M:%S')
          valid_records << {
            click_id: click_id,
            click_time: click_time,
            region: region,
            referrer: referrer,
            sub_id: sub_id
          }
        rescue => e
          Rails.logger.error "Erro ao processar linha: #{e.message}"
          next
        end
      end
      if valid_records.any?
        # upsert_all exige unique index em click_id e user_id
        WebsiteClick.upsert_all(
          valid_records.map { |attrs| attrs.merge(user_id: current_user.id) },
          unique_by: %i[user_id click_id]
        )
        flash[:success] = "#{valid_records.count} cliques importados e atualizados no banco com sucesso!"
        redirect_to clicks_analytics_path
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

  def process_database_analytics_data
    # Análise tradicional do banco de dados
  @clicks = current_user.website_clicks
    
    # Filtros de data
    if params[:start_date].present? && params[:end_date].present?
      @clicks = @clicks.where(click_time: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
    else
      # Últimos 30 dias por padrão
      @clicks = @clicks.where(click_time: 30.days.ago..Time.current)
    end

    @total_clicks = @clicks.count
    
  # Agrupar por sub_id (campanha)
  @clicks_by_sub_id = @clicks.group(:sub_id).count

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

  # Removido método incompleto analytics_data que causava erro de sintaxe
end
