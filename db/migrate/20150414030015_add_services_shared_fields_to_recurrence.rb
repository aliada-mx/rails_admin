class AddServicesSharedFieldsToRecurrence < ActiveRecord::Migration
  def change
    add_column :recurrences, :bathrooms, :integer
    add_column :recurrences, :bedrooms, :integer
    add_column :recurrences, :zone_id, :integer
    add_column :recurrences, :extra_ids, :integer
    add_column :recurrences, :address_id, :integer
    add_column :recurrences, :rooms_hours, :integer
    add_column :recurrences, :hours_after_service, :decimal, precision: 10, scale: 3
    add_column :recurrences, :estimated_hours, :decimal, precision: 10, scale: 3
    add_column :recurrences, :entrance_instructions, :text
    add_column :recurrences, :attention_instructions, :text
    add_column :recurrences, :cleaning_supplies_instructions, :text
    add_column :recurrences, :equipment_instructions, :text
    add_column :recurrences, :garbage_instructions, :text
    add_column :recurrences, :special_instructions, :text
    add_column :recurrences, :forbidden_instructions, :text
  end
end
