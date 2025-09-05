class WebsiteClick < ApplicationRecord
  belongs_to :user

  validates :click_id, presence: true, uniqueness: true
  validates :click_time, presence: true
  validates :region, presence: true
  validates :referrer, presence: true

  scope :by_date_range, ->(start_date, end_date) { where(click_time: start_date..end_date) }
  scope :by_referrer, ->(referrer) { where(referrer: referrer) }
  scope :by_region, ->(region) { where(region: region) }
  scope :by_sub_id, ->(sub_id) { where(sub_id: sub_id) }

  def self.import_from_csv(file_path, user)
    require 'csv'
    
    CSV.foreach(file_path, headers: true, encoding: 'BOM|UTF-8') do |row|
      # Mapear cabeçalhos do CSV para campos do modelo
      click_data = {
        click_id: row['ID dos Cliques'],
        click_time: DateTime.parse(row['Tempo dos Cliques']),
        region: row['Região dos Cliques'],
        sub_id: row['Sub_id'].present? && row['Sub_id'] != '----' ? row['Sub_id'] : nil,
        referrer: row['Referenciador'],
        user: user
      }
      
      # Criar ou atualizar o registro
      website_click = find_or_initialize_by(click_id: click_data[:click_id])
      website_click.assign_attributes(click_data)
      website_click.save!
    end
  end

  def self.total_clicks_by_period(user, start_date, end_date)
    where(user: user, click_time: start_date..end_date).count
  end

  def self.clicks_by_referrer(user, start_date, end_date)
    where(user: user, click_time: start_date..end_date)
      .group(:referrer)
      .count
  end

  def self.clicks_by_region(user, start_date, end_date)
    where(user: user, click_time: start_date..end_date)
      .group(:region)
      .count
  end

  def self.clicks_by_hour(user, start_date, end_date)
    where(user: user, click_time: start_date..end_date)
      .group("DATE_TRUNC('hour', click_time)")
      .count
  end

  def self.clicks_by_day(user, start_date, end_date)
    where(user: user, click_time: start_date..end_date)
      .group("DATE_TRUNC('day', click_time)")
      .count
  end

  def self.clicks_with_sub_id(user, start_date, end_date)
    where(user: user, click_time: start_date..end_date)
      .where.not(sub_id: [nil, '', '----'])
      .group(:sub_id)
      .count
  end

  # Métodos para analisar todos os dados do CSV (sem filtro de período)
  def self.total_clicks_all_time(user)
    where(user: user).count
  end

  def self.clicks_by_referrer_all_time(user)
    where(user: user)
      .group(:referrer)
      .count
  end

  def self.clicks_by_region_all_time(user)
    where(user: user)
      .group(:region)
      .count
  end

  def self.clicks_by_hour_all_time(user)
    where(user: user)
      .group("DATE_TRUNC('hour', click_time)")
      .count
  end

  def self.clicks_by_day_all_time(user)
    where(user: user)
      .group("DATE_TRUNC('day', click_time)")
      .count
  end

  def self.clicks_with_sub_id_all_time(user)
    where(user: user)
      .where.not(sub_id: [nil, '', '----'])
      .group(:sub_id)
      .count
  end
end
