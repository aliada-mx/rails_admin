# -*- encoding : utf-8 -*-
class AddAliadaWorkingHoursIdToSchedules < ActiveRecord::Migration
  def change
    add_column :schedules, :aliada_working_hour_id, :integer
  end

  def data
    AliadaWorkingHour.all.each do |awh|
      awh.create_schedules_until_horizon
    end
  end
end
