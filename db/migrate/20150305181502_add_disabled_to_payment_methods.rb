# -*- encoding : utf-8 -*-
class AddDisabledToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :disabled, :boolean
  end
end
