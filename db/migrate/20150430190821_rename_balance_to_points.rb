class RenameBalanceToPoints < ActiveRecord::Migration
  def change
    rename_column :users, :balance, :points
  end
end
