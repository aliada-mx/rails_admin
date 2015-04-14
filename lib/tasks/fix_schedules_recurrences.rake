namespace :db do
  desc "Fix schedules recurrences"
  task :fix_schedules_recurrences => :environment do
    puts 'Adding recurrence to schedules'
	  Service.with_recurrence.in_the_future.each do |service|
      recurrence = service.recurrence

      service.schedules.each do |schedule|
        if schedule.recurrence_id.nil?

          puts "fixing schedules from the service #{schedule.id}" 

          schedule.recurrence = recurrence
          schedule.save!
        end
      end
    end

    Schedule.where('recurrence_id IS NOT NULL').each do |schedule|
      recurrence = schedule.recurrence

      service = schedule.service
      if service && service.recurrence_id.nil? && recurrence.present?

        puts "fixing service from the schedule #{service.id}" 

        service.recurrence = recurrence
        service.save!
      end
    end

    schedules_without_recurrence = []
    schedules_fixed = []
    Schedule.where('recurrence_id IS NULL').in_the_future.each do |schedule|
      service = schedule.service

      if service.nil?
        schedules_without_recurrence.push(schedule)
        next
      end

      if service.recurrence_id
        schedule.recurrence_id = service.recurrence_id

        schedule.save!
        schedules_fixed.push schedule
      end
    end

    puts "found #{schedules_without_recurrence.size} schedules_without_recurrence"
    puts "fixed #{schedules_fixed.size} schedules"

    Recurrence.all.each do |recurrence|
      recurrence.services.each do |service|
        service.schedules.each do |schedule|
          if schedule.recurrence_id.nil?
            puts "fixing schedules from the recurrence #{schedule.id}"
            schedule.recurrence_id = recurrence.id
            schedule.save!
          end
        end
      end
    end
  end
end
