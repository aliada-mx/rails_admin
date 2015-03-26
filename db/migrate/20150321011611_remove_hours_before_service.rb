class RemoveHoursBeforeService < ActiveRecord::Migration
  def change
    remove_column :services, :hours_before_service, :decimal, precision: 10, scale: 3
  end
end
