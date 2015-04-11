namespace :db do
  desc "Migrate recurrences to one to many"
  task :migrate_recurrences => :environment do
    one_time_from_recurrent = ServiceType.find_or_create_by!(name: 'one-time-from-recurrent', price_per_hour: '65', display_name: 'Una sola vez derivado de uno recurrente', hidden: true)

    Service.with_recurrence.each do |service|
      recurrence = service.recurrence

      base_service = recurrence.base_service
      extra_ids = base_service.extra_ids

      recurrence.services.each do |_service|
        next if _service.id == base_service.id
        
        _service.service_type = one_time_from_recurrent
        _service.update_attributes(extra_ids: extra_ids)
        _service.save!
      end
    end
  end
end
