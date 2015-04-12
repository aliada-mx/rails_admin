# -*- encoding : utf-8 -*-
class AddPeriodicityToRecurrences < ActiveRecord::Migration
  def change
    add_column :recurrences, :periodicity, :integer
  end
end
