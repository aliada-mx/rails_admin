# -*- encoding : utf-8 -*-
class AddPaymentMethodIdToServices < ActiveRecord::Migration
  def change
    add_column :services, :payment_method_id, :integer
  end
end
