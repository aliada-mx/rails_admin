# -*- encoding : utf-8 -*-
class ConvertToDatetime < ActiveRecord::Migration
  def change
    #remove_column :services, :date, :date
    #remove_column :services, :time, :time

    add_column :services, :datetime, :datetime
  end
end
