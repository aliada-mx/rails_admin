# -*- encoding : utf-8 -*-
class RemoveSchedulesZones < ActiveRecord::Migration
  def change
    drop_table :schedules_zones
  end
end