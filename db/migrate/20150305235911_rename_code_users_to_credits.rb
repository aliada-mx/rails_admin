# -*- encoding : utf-8 -*-
class RenameCodeUsersToCredits < ActiveRecord::Migration
  def change
    rename_table :code_users, :credits
  end
end
