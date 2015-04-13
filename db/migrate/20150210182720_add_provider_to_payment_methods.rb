# -*- encoding : utf-8 -*-
class AddProviderToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :provider, :string
  end
end
