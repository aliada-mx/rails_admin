class ChangeWeekDayForStartingDatetimeInRecurrences < ActiveRecord::Migration
  def change
    add_column :recurrences, :starting_datetime, :datetime
    remove_column :recurrences, :day_of_week, :integer
  end
end
