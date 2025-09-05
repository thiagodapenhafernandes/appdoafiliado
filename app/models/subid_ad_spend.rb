class SubidAdSpend < ApplicationRecord
  belongs_to :user
  
  validates :subid, presence: true
  validates :ad_spend, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_investment, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Buscar gasto por SubID para um período específico
  scope :for_period, ->(start_date, end_date) {
    where('period_start <= ? AND period_end >= ?', end_date, start_date)
  }
  
  # Buscar gasto por SubID específico
  scope :for_subid, ->(subid) { where(subid: subid) }
  
  # Método para buscar gasto de um SubID específico do usuário
  def self.ad_spend_for_subid(user, subid, date = Date.current)
    for_subid(subid)
      .where(user: user)
      .for_period(date, date)
      .sum(:ad_spend)
  end
end
