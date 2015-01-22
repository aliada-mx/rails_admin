class ChangeFullNameInUsers < ActiveRecord::Migration
  def change
    remove_column :users, :full_name, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
  end
end
