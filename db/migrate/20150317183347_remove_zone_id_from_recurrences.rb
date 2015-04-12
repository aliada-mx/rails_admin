# -*- encoding : utf-8 -*-
class RemoveZoneIdFromRecurrences < ActiveRecord::Migration
  def change
    remove_column :recurrences, :zone_id, :integer 
  end
end
