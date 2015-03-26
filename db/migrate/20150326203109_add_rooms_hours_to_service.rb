class AddRoomsHoursToService < ActiveRecord::Migration
  def change
    add_column :services, :rooms_hours, :decimal, precision: 10, scale: 3
  end
end
