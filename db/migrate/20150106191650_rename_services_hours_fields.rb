class RenameServicesHoursFields < ActiveRecord::Migration
  def change
    rename_column :services, :time_to_arrive, :hours_before_service
    rename_column :services, :time_to_leave, :hours_after_service
    rename_column :services, :hours, :billable_hours
  end
end
