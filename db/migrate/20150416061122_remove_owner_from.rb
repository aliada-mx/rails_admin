class RemoveOwnerFrom < ActiveRecord::Migration
  def change
    remove_column :recurrences, :owner
    remove_column :aliada_working_hours, :owner
  end
end
