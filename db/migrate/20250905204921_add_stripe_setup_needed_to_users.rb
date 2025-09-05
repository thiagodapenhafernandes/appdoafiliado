class AddStripeSetupNeededToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :stripe_setup_needed, :boolean
  end
end
