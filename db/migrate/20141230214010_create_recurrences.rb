# -*- encoding : utf-8 -*-
class CreateRecurrences < ActiveRecord::Migration
  def change
    create_table :recurrences do |t|
      t.belongs_to :user, index: true
      t.string :day_of_week
      t.integer :hour
      t.string :status

      t.timestamps null: false
    end
    add_foreign_key :recurrences, :users
  end
end
