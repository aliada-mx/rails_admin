class AddEndTimeToServices < ActiveRecord::Migration
  def change
    add_column :services, :end_time, :time
  end
end
