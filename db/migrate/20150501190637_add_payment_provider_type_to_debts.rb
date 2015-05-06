class AddPaymentProviderTypeToDebts < ActiveRecord::Migration
  def change
    add_column :debts, :payment_provider_choice_type, :string
  end
end
