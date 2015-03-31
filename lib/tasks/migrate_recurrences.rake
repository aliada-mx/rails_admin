namespace :db do
  desc "Migrate recurrences to one to many"
  task :migrate_recurrences => :environment do
    one_timer = ServiceType.one_time

    Service.with_recurrence.each do |service|
      recurrence = service.recurrence

      base_service = recurrence.base_service

      recurrence.services.each do |_service|
        next if _service.id == base_service.id
        
        _service.service_type = one_timer
        _service.save!
      end
    end
  end
end
