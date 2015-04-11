# -*- encoding : utf-8 -*-
class AddEndTimeToServices < ActiveRecord::Migration
  def change
    add_column :services, :end_time, :time
  end
end
