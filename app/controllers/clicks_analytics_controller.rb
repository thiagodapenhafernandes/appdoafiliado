require 'csv'
require 'json'
require 'securerandom'

class ClicksAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :log_action_execution

  # Listagem de importações salvas
  def imports
    @imports = WebsiteClickImport.order(created_at: :desc).includes(:website_clicks)
  end

  # Remove importação específica e registros associados
  def delete_import
    import = WebsiteClickImport.find(params[:id])
    count = import.website_clicks.count
    import.website_clicks.destroy_all
    import.destroy
    flash[:success] = "Importação e #{count} cliques removidos com sucesso."
    redirect_to clicks_analytics_imports_path
  end

  # Persiste dados previamente analisados em CSV no banco
  def persist_csv_to_db
    file_id = params[:file_id] || session[:csv_analytics_file_id]
    return redirect_to clicks_analytics_path, alert: 'Arquivo não encontrado.' unless file_id

    temp_file_path = Rails.root.join('tmp', "csv_analytics_#{file_id}.json")
    return redirect_to clicks_analytics_path, alert: 'Arquivo não encontrado.' unless File.exist?(temp_file_path)

    csv_temp = Rails.root.join('tmp', "csv_import_#{file_id}.csv")

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
      flash[:error] = 'Informe a data inicial e final para deletar por período.'
    end
    redirect_to clicks_analytics_path
  end

  # Deleta todos os cliques do usuário
  def destroy_all
    WebsiteClick.delete_all_for_user(current_user)
    flash[:success] = 'Todos os cliques foram deletados com sucesso.'
    redirect_to clicks_analytics_path
  end

  def index
    unless current_user.can_access_clicks_analytics?
      @advanced_tracking_locked = true
      return
    end

    if params[:from_csv] == 'true' && (session[:csv_analytics_file_id] || params[:file_id])
      @from_csv = true
      process_csv_analytics_data
    else
      @from_csv = false
      process_database_analytics_data
    end

    respond_to do |format|
      format.html
      format.json { render json: analytics_data }
    end
  end

  def import_csv
    unless current_user.can_access_clicks_analytics?
      if request.post?
        redirect_to plans_path, alert: 'Importação de cliques faz parte do Plano Completo. Assine para liberar o recurso.'
      else
        @advanced_tracking_locked = true
      end
      return
    end

    return unless request.post?

    process_csv_upload
  end

  def process_csv_upload
    cleanup_old_csv_files

    if params[:csv_file].blank?
      flash[:error] = 'Por favor, selecione um arquivo CSV.'
      redirect_to clicks_analytics_import_csv_path
      return
    end

    csv_file = params[:csv_file]

    unless ['text/csv', 'application/csv', 'application/vnd.ms-excel'].include?(csv_file.content_type) ||
           csv_file.original_filename.end_with?('.csv')
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

      csv_data = csv_data.force_encoding('UTF-8') if csv_data.encoding != Encoding::UTF_8
      csv_data = csv_data.force_encoding('ISO-8859-1').encode('UTF-8', invalid: :replace, undef: :replace) unless csv_data.valid_encoding?
      csv_data = csv_data.sub(/\A\uFEFF/, '')

      valid_records = []

      CSV.parse(csv_data, headers: true, liberal_parsing: true) do |row|
        click_id = row['ID dos Cliques']
        click_time_str = row['Tempo dos Cliques']
        region = row['Região dos Cliques'] || row['Região'] || 'Desconhecido'
        sub_id = row['Sub_id'] || row['SubID'] || row['sub_id'] || ''
        referrer = row['Referenciador'] || row['Referrer'] || 'Shopee'
        commission = row['Comissão Estimada']

        next if click_id.blank? || click_time_str.blank?

        begin
          click_time = Time.strptime(click_time_str, '%Y-%m-%d %H:%M:%S')
          valid_records << {
            click_id: click_id,
            click_time: click_time,
            commission: commission.to_f,
            region: region,
            referrer: referrer,
            sub_id: sub_id
          }
        rescue => e
          Rails.logger.error "Erro ao processar linha do CSV: #{e.message}"
        end
      end

      if valid_records.any?
        temp_file_id = SecureRandom.uuid
        temp_file_path = Rails.root.join('tmp', "csv_analytics_#{temp_file_id}.json")
        File.write(temp_file_path, valid_records.to_json)

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
    file_id = params[:file_id] || session[:csv_analytics_file_id]
    return unless file_id

    temp_file_path = Rails.root.join('tmp', "csv_analytics_#{file_id}.json")
    return unless File.exist?(temp_file_path)

    raw_data = JSON.parse(File.read(temp_file_path), symbolize_names: true)

    raw_data.each do |record|
      record[:click_time] = Time.parse(record[:click_time]) if record[:click_time].is_a?(String)
    end

    @csv_data = raw_data
    filtered = filter_csv_data(@csv_data.dup)

    @filtered_csv_data = filtered
    build_csv_dashboards(filtered)
  end

  def process_database_analytics_data
    @clicks = current_user.website_clicks

    if params[:start_date].present? && params[:end_date].present?
      range = params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day
      @clicks = @clicks.where(click_time: range)
    else
      @clicks = @clicks.where(click_time: 30.days.ago..Time.current)
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

    @total_clicks = @clicks.count

    region_data = @clicks.group(:region).count
    referrer_data = @clicks.group(:referrer).count
    hourly_data = @clicks.group_by_hour(:click_time).count
    daily_data = @clicks.group_by_day(:click_time).count

    if @clicks.any?
      @period_start = @clicks.minimum(:click_time).to_date
      @period_end = @clicks.maximum(:click_time).to_date
    else
      @period_start = @period_end = Date.current
    end

    @period_info = get_data_period_info(@period_start, @period_end)
    @referrer_chart_data = format_referrer_chart_data(referrer_data)
    @region_chart_data = format_region_chart_data(region_data)
    @hourly_chart_data = format_hourly_chart_data(hourly_data)
    @daily_chart_data = format_daily_chart_data(daily_data)
    @peak_hour = find_peak_hour(hourly_data)
    @top_referrer = referrer_data.max_by { |_, count| count }
    @top_region = region_data.max_by { |_, count| count }

    @clicks_by_referrer = referrer_data
    @clicks_by_region = region_data
    @clicks_by_hour = hourly_data
    @clicks_by_day = daily_data
  end

  def filter_csv_data(records)
    filtered = records

    if params[:start_date].present? && params[:end_date].present?
      start_date = params[:start_date].to_date.beginning_of_day
      end_date = params[:end_date].to_date.end_of_day
      filtered = filtered.select { |row| row[:click_time].between?(start_date, end_date) }
    end

    if params[:sub_id].present?
      term = params[:sub_id].downcase
      filtered = filtered.select { |row| row[:sub_id].to_s.downcase.include?(term) }
    end
    if params[:click_id].present?
      term = params[:click_id].downcase
      filtered = filtered.select { |row| row[:click_id].to_s.downcase.include?(term) }
    end
    if params[:region].present?
      term = params[:region].downcase
      filtered = filtered.select { |row| row[:region].to_s.downcase.include?(term) }
    end
    if params[:referrer].present?
      term = params[:referrer].downcase
      filtered = filtered.select { |row| row[:referrer].to_s.downcase.include?(term) }
    end

    filtered
  end

  def build_csv_dashboards(records)
    @total_clicks = records.count
    @total_commission = records.sum { |record| record[:commission] || 0 }

    region_data = records.group_by { |record| record[:region] }.transform_values(&:count)
    referrer_data = records.group_by { |record| record[:referrer] }.transform_values(&:count)
    hourly_data = records.group_by { |record| record[:click_time].hour }.transform_values(&:count).sort.to_h
    daily_data = records.group_by { |record| record[:click_time].to_date }.transform_values(&:count).sort.to_h

    dates = records.map { |record| record[:click_time].to_date }
    if dates.any?
      @period_start = dates.min
      @period_end = dates.max
      @period_info = get_data_period_info(@period_start, @period_end)
    else
      @period_start = @period_end = Date.current
      @period_info = get_data_period_info(@period_start, @period_end)
    end

    @referrer_chart_data = format_referrer_chart_data(referrer_data)
    @region_chart_data = format_region_chart_data(region_data)
    @hourly_chart_data = format_hourly_chart_data(hourly_data)
    @daily_chart_data = format_daily_chart_data(daily_data)
    @peak_hour = find_peak_hour(hourly_data)
    @top_referrer = referrer_data.max_by { |_, count| count }
    @top_region = region_data.max_by { |_, count| count }

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
    Rails.logger.info("ClicksAnalyticsController##{action_name} - #{request.method}")
  end

  def cleanup_old_csv_files
    Dir.glob(Rails.root.join('tmp', 'csv_analytics_*.json')).each do |file_path|
      File.delete(file_path) if File.mtime(file_path) < 2.hours.ago
    end
  end
end
