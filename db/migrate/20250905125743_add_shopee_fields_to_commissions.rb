class AddShopeeFieldsToCommissions < ActiveRecord::Migration[7.1]
  def change
    add_column :commissions, :external_id, :string # ID único da API (se vier da API)
    add_column :commissions, :source, :string, default: 'csv' # 'csv' ou 'shopee_api'
    
    # Índices para performance e queries
    add_index :commissions, :external_id
    add_index :commissions, :source
    
    # Atualizar registros existentes como 'csv'
    reversible do |dir|
      dir.up do
        execute "UPDATE commissions SET source = 'csv' WHERE source IS NULL"
      end
    end
  end
end
