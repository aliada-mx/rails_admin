# -*- encoding : utf-8 -*-
class AddCategoryToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :category, :string
  end
end
