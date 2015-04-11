# -*- encoding : utf-8 -*-
class AddBeginTimeToServices < ActiveRecord::Migration
  def change
    add_column :services, :begin_time, :time
  end
end
