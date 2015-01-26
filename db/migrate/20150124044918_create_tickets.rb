class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :classification
      t.integer :relevant_object_id
      t.string :relevant_object_type
      t.text :message
      t.string :action_needed

      t.timestamps null: false
    end
  end
end
