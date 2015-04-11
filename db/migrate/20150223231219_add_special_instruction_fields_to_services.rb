# -*- encoding : utf-8 -*-
class AddSpecialInstructionFieldsToServices < ActiveRecord::Migration
  def change
    add_column :services, :bring_cleaning_products, :boolean
    add_column :services, :entrance_instructions, :text
    add_column :services, :cleaning_supplies_instructions, :text
    add_column :services, :garbage_instructions, :text
    add_column :services, :attention_instructions, :text
    add_column :services, :equipment_instructions, :text
    add_column :services, :forbidden_instructions, :text
  end
end
