namespace :db do
  desc "Fix recurrences with wrong service type"
  task :fix_recurrences_with_wrong_service_type => :environment do
   
    ActiveRecord::Base.transaction do
      broken_services = []
      # Find all whose service type shoud be oner timer but is recurrent
      User.all.each do |user|
        recurrent_services = user.services.recurrent.not_canceled.to_a.uniq { |s| s.recurrence_id }.select { |s| s.recurrence.try(:active?) }

        recurrent_services.each do |service|
          recurrence = service.recurrence

          services = recurrence.services.ordered_by_datetime.in_the_future.select do |service| 
            broken_services.push(service) if service.recurrent?
          end

        end
      end

      puts "found #{broken_services.size} services that should be one_timer_from_recurrent"
      fixed = {}

      broken_services.each do |service|
        recurrence = service.recurrence
        base_service = recurrence.base_service

        next if service.id == base_service.id

        next if fixed[service.id]

        service.service_type_id = 3
        service.save!
        fixed[service.id] = true

      end

      puts "fixed #{fixed.size} services"

    end


  end
end
