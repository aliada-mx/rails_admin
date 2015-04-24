# -*- encoding : utf-8 -*-
class FillRecurrenceMissingFields < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      Recurrence.active.where(estimated_hours: nil, hours_after_service: nil).each do |recurrence|
        recurrence.services.each do |service|
          shared_attributes = service.shared_attributes.except('service_type_id','price','recurrence_id')

          recurrence.update_attributes(shared_attributes)
          next
        end

        recurrence.user.services.each do |service|
          shared_attributes = service.shared_attributes.except('service_type_id','price','recurrence_id')

          recurrence.update_attributes(shared_attributes)
          break
        end

      end
    end
  end
end
