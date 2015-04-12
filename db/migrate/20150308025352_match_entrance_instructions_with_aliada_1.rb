# -*- encoding : utf-8 -*-
class MatchEntranceInstructionsWithAliada1 < ActiveRecord::Migration
  def change
    remove_column :services, :bring_cleaning_products, :boolean
    remove_column :services, :entrance_instructions, :text
    add_column :services, :entrance_instructions, :boolean
  end
end
