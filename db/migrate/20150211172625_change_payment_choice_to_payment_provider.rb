# -*- encoding : utf-8 -*-
class ChangePaymentChoiceToPaymentProvider < ActiveRecord::Migration
  def change
    rename_column :payment_choices, :payment_method_type, :payment_provider_type 
    rename_column :payment_choices, :payment_method_id, :payment_provider_id
    rename_table :payment_choices, :payment_provider_choices

    rename_column :payments, :payment_choice_id, :payment_method_provider_id

    rename_column :payment_methods, :provider, :payment_provider_type
    remove_column :payment_methods, :code_type_id, :integer
  end
end
