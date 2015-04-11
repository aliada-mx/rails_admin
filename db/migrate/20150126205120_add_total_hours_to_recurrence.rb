# -*- encoding : utf-8 -*-
class AddTotalHoursToRecurrence < ActiveRecord::Migration
  def change
    add_column :recurrences, :total_hours, :integer
  end
end
