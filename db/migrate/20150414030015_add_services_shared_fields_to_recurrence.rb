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

    create_table :extra_recurrences do |t|
      t.integer :extra_id
      t.integer :recurrence_id

      t.timestamps null: false
    end
  end

  def data
    failed_recurrences = []
    recurrences_without_base_service = []
    ActiveRecord::Base.transaction do
      Recurrence.active.where(owner: 'user').each do |recurrence|
        base_service = recurrence.base_service
        if base_service
          shared_attributes = base_service.shared_attributes.except('service_type_id','price', 'recurrence_id')
        elsif recurrence.user
          shared_attributes = recurrence.user.services.first.shared_attributes.except('service_type_id','price','recurrence_id')

          recurrences_without_base_service.push(recurrence)
        else
          failed_recurrences.push(recurrence)
          next
        end

        recurrence.update_attributes(shared_attributes)
      end

      # raise ActiveRecord::Rollback
    end
    puts "found #{recurrences_without_base_service.count} recurrences_without_base_service"
    puts "found #{failed_recurrences.count} failed_recurrences"
  end
end
