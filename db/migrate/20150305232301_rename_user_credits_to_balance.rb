class RenameUserCreditsToBalance < ActiveRecord::Migration
  def change
    rename_column :users, :credits, :balance
  end
end
