# -*- encoding : utf-8 -*-
class ChangeNumberAndInteriorNumberTypeInAddresses < ActiveRecord::Migration
  def change
    change_column :addresses, :number, :string
    change_column :addresses, :interior_number, :string
  end
end
