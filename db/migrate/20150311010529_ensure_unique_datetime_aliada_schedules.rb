class EnsureUniqueDatetimeAliadaSchedules < ActiveRecord::Migration
  def change
    add_index(:schedules, [:datetime, :aliada_id], :unique => true)
  end
end
