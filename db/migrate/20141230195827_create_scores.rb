# -*- encoding : utf-8 -*-
class CreateScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.belongs_to :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :scores, :users
  end
end
