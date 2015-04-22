class RemoveTotalHoursFromRecurrence < ActiveRecord::Migration
  def change
    remove_column :recurrences, :total_hours
  end
end
