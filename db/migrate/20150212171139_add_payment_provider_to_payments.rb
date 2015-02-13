class AddPaymentProviderToPayments < ActiveRecord::Migration
  def change
    rename_column :payments, :payment_method_provider_id, :payment_provider_id
    add_column :payments, :payment_provider_type, :string
  end
end
