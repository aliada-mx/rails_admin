# -*- encoding : utf-8 -*-
class AddBillableHoursToService < ActiveRecord::Migration
  def change
    add_column :services, :billable_hours, :decimal, precision: 10, scale: 3, default: 0.0
  end
end
