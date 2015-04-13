# -*- encoding : utf-8 -*-
class AddZoneToRecurrences < ActiveRecord::Migration
  def change
    add_column :recurrences, :zone_id, :integer
  end
end
