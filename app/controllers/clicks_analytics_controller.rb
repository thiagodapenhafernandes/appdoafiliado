class ClicksAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_advanced_tracking_access

  def index
    # Analisar todos os dados importados do CSV (sem filtro de período)
    @total_clicks = WebsiteClick.total_clicks_all_time(current_user)
    @clicks_by_referrer = WebsiteClick.clicks_by_referrer_all_time(current_user)
    @clicks_by_region = WebsiteClick.clicks_by_region_all_time(current_user)
    @clicks_by_hour = WebsiteClick.clicks_by_hour_all_time(current_user)
    @clicks_by_day = WebsiteClick.clicks_by_day_all_time(current_user)
    @clicks_with_sub_id = WebsiteClick.clicks_with_sub_id_all_time(current_user)
    
    # Período dos dados (automático baseado nos dados importados)
    @date_range_info = get_data_period_info
    
    # Dados para gráficos
    @referrer_chart_data = format_referrer_chart_data(@clicks_by_referrer)
    @region_chart_data = format_region_chart_data(@clicks_by_region)
    @hourly_chart_data = format_hourly_chart_data(@clicks_by_hour)
    @daily_chart_data = format_daily_chart_data(@clicks_by_day)
    
    # Métricas adicionais
    @peak_hour = find_peak_hour(@clicks_by_hour)
    @top_referrer = @clicks_by_referrer.max_by { |k, v| v }
    @top_region = @clicks_by_region.max_by { |k, v| v }
    
    respond_to do |format|
      format.html
      format.json { render json: analytics_data }
    end
  end

  private

  def get_data_period_info
    clicks = current_user.website_clicks
    return { start_date: nil, end_date: nil, total_days: 0 } if clicks.empty?
    
    start_date = clicks.minimum(:click_time).to_date
    end_date = clicks.maximum(:click_time).to_date
    total_days = (end_date - start_date).to_i + 1
    
    {
      start_date: start_date,
      end_date: end_date,
      total_days: total_days,
      formatted_range: "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}"
    }
  end

  def format_referrer_chart_data(data)
    {
      labels: data.keys,
      datasets: [{
        label: 'Cliques por Fonte',
        data: data.values,
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
    {
      labels: data.keys,
      datasets: [{
        label: 'Cliques por Região',
        data: data.values,
        backgroundColor: [
          '#FF6384',
          '#36A2EB',
          '#FFCE56',
          '#4BC0C0',
          '#9966FF'
        ],
        borderWidth: 1
      }]
    }
  end

  def format_hourly_chart_data(data)
    # Organizar por hora
    hours = (0..23).map do |hour|
      hour_key = data.keys.find { |k| k.strftime('%H').to_i == hour }
      [hour, hour_key ? data[hour_key] : 0]
    end.to_h

    {
      labels: hours.keys.map { |h| "#{h}:00" },
      datasets: [{
        label: 'Cliques por Hora',
        data: hours.values,
        borderColor: '#36A2EB',
        backgroundColor: 'rgba(54, 162, 235, 0.1)',
        tension: 0.1,
        fill: true
      }]
    }
  end

  def format_daily_chart_data(data)
    # Organizar dados diários
    sorted_data = data.sort_by { |date, _| date }
    
    {
      labels: sorted_data.map { |date, _| date.strftime('%d/%m') },
      datasets: [{
        label: 'Cliques por Dia',
        data: sorted_data.map { |_, clicks| clicks },
        borderColor: '#FF6384',
        backgroundColor: 'rgba(255, 99, 132, 0.1)',
        tension: 0.1,
        fill: true
      }]
    }
  end

  def find_peak_hour(hourly_data)
    return nil if hourly_data.empty?
    peak = hourly_data.max_by { |_, clicks| clicks }
    peak[0].strftime('%H:00') if peak
  end

  def analytics_data
    {
      total_clicks: @total_clicks,
      clicks_by_referrer: @clicks_by_referrer,
      clicks_by_region: @clicks_by_region,
      peak_hour: @peak_hour,
      top_referrer: @top_referrer,
      top_region: @top_region,
      charts: {
        referrer: @referrer_chart_data,
        region: @region_chart_data,
        hourly: @hourly_chart_data,
        daily: @daily_chart_data
      }
    }
  end

  private

  def check_advanced_tracking_access
    unless current_user.can_access_advanced_tracking?
      redirect_to dashboard_path, alert: 'Analytics de cliques avançados estão disponíveis apenas nos planos Pro e Elite. Faça upgrade para acessar!'
    end
  end
end
