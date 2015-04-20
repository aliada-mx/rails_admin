class AddReportedTimeField < ActiveRecord::Migration
  def change
    add_column :services, :hours_worked, :decimal
  end
end
