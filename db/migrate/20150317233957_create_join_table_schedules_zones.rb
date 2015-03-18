class CreateJoinTableSchedulesZones < ActiveRecord::Migration
  def change
    create_join_table :schedules, :zones do |t|
      t.integer :zone_id
      t.integer :schedule_id
    end
  end
end
