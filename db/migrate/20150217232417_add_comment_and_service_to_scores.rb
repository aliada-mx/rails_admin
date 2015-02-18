class AddCommentAndServiceToScores < ActiveRecord::Migration
  def change
    add_column :scores, :comment, :text
    add_reference :scores, :service, index: true
    add_foreign_key :scores, :services
  end
end
