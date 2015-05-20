class AddMinutesWorkedToServices < ActiveRecord::Migration
  def change
    add_column :services, :minutes_worked, :integer, default: 0
  end
end
