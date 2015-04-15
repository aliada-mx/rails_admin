class AddRecurrencesExtras < ActiveRecord::Migration
  def change
    create_table :extra_recurrences do |t|
      t.integer :extra_id
      t.integer :recurrence_id

      t.timestamps null: false
    end
  end
end
