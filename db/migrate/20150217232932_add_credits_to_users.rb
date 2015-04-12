# -*- encoding : utf-8 -*-
class AddCreditsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :credits, :decimal, precision: 7, scale: 2
  end
end
