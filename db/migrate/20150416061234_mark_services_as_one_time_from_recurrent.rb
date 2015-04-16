class MarkServicesAsOneTimeFromRecurrent < ActiveRecord::Migration
  def change
    Service.with_recurrence.each do |service|
      service.service_type = ServiceType.one_time_from_recurrent
      service.save!
    end
  end
end
