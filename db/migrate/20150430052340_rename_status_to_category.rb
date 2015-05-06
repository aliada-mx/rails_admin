class RenameStatusToCategory < ActiveRecord::Migration
  def change
    rename_column :debts, :status, :category
  end
end
