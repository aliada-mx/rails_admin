class AddAliadaIds < ActiveRecord::Migration
  def change
    add_column :services, :aliada_id, :integer
    add_column :recurrences, :aliada_id, :integer
    add_column :schedules, :aliada_id, :integer
  end
end
