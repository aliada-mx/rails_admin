# -*- encoding : utf-8 -*-
class RemovePaymentMethodFromService < ActiveRecord::Migration
  def change
    remove_column :services, :payment_method_id, :integer
  end
end
