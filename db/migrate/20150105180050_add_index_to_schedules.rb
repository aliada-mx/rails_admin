# -*- encoding : utf-8 -*-
class AddIndexToSchedules < ActiveRecord::Migration
  def change
    add_index :schedules, [:user_id, :datetime], unique: true
  end
end
