class RemoveIndexScoresOnServiceId < ActiveRecord::Migration
  def change
    remove_index :scores, :service_id
  end
end
