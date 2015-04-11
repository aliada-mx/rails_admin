# -*- encoding : utf-8 -*-
class AddBenefitsToServiceTypes < ActiveRecord::Migration
  def change
    add_column :service_types, :benefits, :text
  end
end
