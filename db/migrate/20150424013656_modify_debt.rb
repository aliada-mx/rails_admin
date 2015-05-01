class ModifyDebt < ActiveRecord::Migration
  def change
    remove_column :debts, :payment_method_id
    add_reference :debts, :payment_provider_choice
    #remove_foreign_key :debts, :payment_method
    #add_foreign_key :debts, :payment_provider_choice
  end
end
