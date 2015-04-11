# -*- encoding : utf-8 -*-
class DropPostalCodeZones < ActiveRecord::Migration
  def change
    drop_table :postal_code_zones
  end
end
