class AddTypeToRecurrences < ActiveRecord::Migration
  def change
    add_column :recurrences, :owner, :string
  end
end
