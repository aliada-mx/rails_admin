# -*- encoding : utf-8 -*-
class AddReportedTimeField < ActiveRecord::Migration
  def change
    add_column :services, :hours_worked, :decimal
  end
end
