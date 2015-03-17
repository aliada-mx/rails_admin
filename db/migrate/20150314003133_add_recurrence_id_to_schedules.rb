class AddRecurrenceIdToSchedules < ActiveRecord::Migration
  def change
    add_column :schedules, :recurrence_id, :integer
  end
end
