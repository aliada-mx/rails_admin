# -*- encoding : utf-8 -*-
class CleanAliadaWorkingHours < ActiveRecord::Migration
  def change
    AliadaWorkingHour.all.each do |awh|
      awh.destroy if awh.owner == 'user'
    end
  end
end
