# -*- encoding : utf-8 -*-
class AddMapCenterLatitudeToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :map_center_latitude, :decimal, {precision: 10, scale: 6}
    add_column :addresses, :map_center_longitude, :decimal, {precision: 10, scale: 6}
  end
end
