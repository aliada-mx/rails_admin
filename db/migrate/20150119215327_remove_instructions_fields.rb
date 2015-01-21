class RemoveInstructionsFields < ActiveRecord::Migration
  def change
    remove_column :services, :aliada_entry_instruction, :text
    remove_column :services, :cleaning_products_instruction, :string
    remove_column :services, :cleaning_utensils_instruction, :text
    remove_column :services, :trash_location_instruction, :text
    remove_column :services, :special_attention_instruction, :text
    remove_column :services, :special_equipment_instruction, :text
    remove_column :services, :do_not_touch_instruction, :text
  end
end

