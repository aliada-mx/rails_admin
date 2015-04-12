# -*- encoding : utf-8 -*-
class ChangePriceToPriceHourToServiceTypes < ActiveRecord::Migration
  def change
    remove_column :service_types, :price, :integer
    add_column :service_types, :price_per_hour, :integer
  end
end
