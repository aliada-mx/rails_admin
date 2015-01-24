class ChangeDatetimeToWeekDayHour < ActiveRecord::Migration
  def change
    remove_column :recurrences, :starting_datetime, :datetime

    add_column :recurrences, :weekday, :string
    add_column :recurrences, :hour, :integer
  end
end
