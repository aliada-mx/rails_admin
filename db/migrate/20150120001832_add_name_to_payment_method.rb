# -*- encoding : utf-8 -*-
class AddNameToPaymentMethod < ActiveRecord::Migration
  def change
    add_column :payment_methods, :name, :string
  end
end
