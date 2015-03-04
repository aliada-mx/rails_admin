class ChangeIndexForServiceInScores < ActiveRecord::Migration
  def change
    remove_index "scores", name: "index_scores_on_service_id"
    add_index "scores", "service_id", name: "index_scores_on_service_id", unique: true, using: :btree
  end
end
