# -*- encoding : utf-8 -*-
class RemoveSchedulesIndex < ActiveRecord::Migration
  def change
    remove_index :schedules, column: [:user_id, :datetime]
  end
end
