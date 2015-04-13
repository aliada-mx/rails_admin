# -*- encoding : utf-8 -*-
class ChangeBillableHoursAndAddEstimatedHoursToServices < ActiveRecord::Migration
  def change
    rename_column :services, :billable_hours, :billed_hours 
    add_column :services, :estimated_hours, :decimal, precision: 10, scale: 3
  end
end
