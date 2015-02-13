class FixPaymentProviderType < ActiveRecord::Migration
  def change
    remove_column :payment_provider_choices, :payment_provider_type, :integer
    add_column :payment_provider_choices, :payment_provider_type, :string
  end
end
