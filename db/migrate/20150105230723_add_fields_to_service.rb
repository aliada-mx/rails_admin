class AddFieldsToService < ActiveRecord::Migration
  def change
    add_column :services, :hours, :decimal, precision: 10, scale: 3
    add_column :services, :time_to_arrive, :decimal, precision: 10, scale: 3
    add_column :services, :time_to_leave, :decimal, precision: 10, scale: 3
  end
end
