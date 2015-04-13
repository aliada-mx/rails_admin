# -*- encoding : utf-8 -*-
class AddClientInstructionsFieldsToServices < ActiveRecord::Migration
  def change
    add_column :services, :bathrooms,                     :integer
    add_column :services, :bedrooms,                      :integer
    add_column :services, :aliada_entry_instruction,      :text
    add_column :services, :cleaning_products_instruction, :string
    add_column :services, :cleaning_utensils_instruction, :text
    add_column :services, :trash_location_instruction,    :text
    add_column :services, :special_attention_instruction, :text
    add_column :services, :special_equipment_instruction, :text
    add_column :services, :do_not_touch_instruction,      :text
    add_column :services, :special_instructions,          :text
  end
end
