# -*- encoding : utf-8 -*-
class AddNameToPostalCodes < ActiveRecord::Migration
  def change
    add_column :postal_codes, :name, :string
  end
end
