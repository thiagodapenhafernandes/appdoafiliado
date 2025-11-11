class ConsolidatePlansToSingleDefault < ActiveRecord::Migration[7.1]
  def up
    say_with_time 'Configurando Plano Completo' do
      Plan.reset_column_information
      default_plan = Plan.find_or_initialize_by(name: Plan::DEFAULT_PLAN_NAME)
      default_plan.description = 'Acesso completo ao LinkFlow com todos os recursos liberados.'
      default_plan.price_cents = 4700
      default_plan.currency = 'BRL'
      default_plan.max_links = -1
      default_plan.popular = true
      default_plan.features = [
        'Links ilimitados',
        'Analytics avançado em tempo real',
        'Importação de cliques e comissões via CSV',
        'Rastreamento avançado com SubIDs',
        'Exportação de relatórios em PDF',
        'Suporte estratégico prioritário'
      ]
      default_plan.active = true
      default_plan.save!
    end

    say_with_time 'Desativando planos legados' do
      Plan.where.not(name: Plan::DEFAULT_PLAN_NAME).update_all(active: false, popular: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Configuração de plano único não pode ser revertida automaticamente.'
  end
end
