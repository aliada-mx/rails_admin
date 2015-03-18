class RemoveZoneIdFromSchedules < ActiveRecord::Migration
  def change
    remove_column :schedules, :zone_id, :integer 
  end
end
