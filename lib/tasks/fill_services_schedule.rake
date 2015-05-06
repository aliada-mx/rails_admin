namespace :db do
  desc "Fill services schedules"
  task :fill_services_schedules => :environment do

    puts 'checking aliadas schedules'
    missing_schedules = []

    SCHEDULES_IN_OTHER_SERVICE = Hash.new{ |h,k| h[k] = [] }
    SCHEDULES_CORRECTED = []

    def correct_service_schedules(beginning, ending, service, status)
      Time.iterate_in_hour_steps(beginning, ending).each do |datetime|
        schedule = Schedule.find_by(aliada_id: service.aliada_id, datetime: datetime)

        if schedule 
          if schedule.service_id && service.id != schedule.service_id
            SCHEDULES_IN_OTHER_SERVICE[service.id].push schedule
            next
          else
            puts "setting schedule #{status} #{schedule.datetime} #{schedule.id}"
            if schedule.status != status ||
               schedule.service_id != service.id ||
               schedule.recurrence_id != service.recurrence_id ||
               schedule.user_id != service.user_id

              SCHEDULES_CORRECTED.push(schedule)
            end

            schedule.service_id = service.id
            schedule.user_id = service.user_id
            schedule.recurrence_id = service.recurrence_id
            schedule.status = status
            schedule.save!
          end
        end
      end
    end

    ActiveRecord::Base.transaction do
      Service.not_canceled.in_the_future.each do |service|

        next unless service.schedules.count < service.total_hours
        puts "found service with #{service.schedules.count} schedules count and total hours #{service.total_hours}"

        # booked hours first
        booked_beginning = service.datetime
        booked_ending = ( service.datetime + service.estimated_hours.hours ).beginning_of_hour

        if booked_ending.hour == 3 # 9 pm in mexico city
          booked_ending -= 1
        end

        puts "for service with datetime #{service.datetime} #{service.id}"
        correct_service_schedules(booked_beginning, booked_ending, service, 'booked')

        # Padding hours
        padding_beginning = booked_ending
        padding_ending = padding_beginning + service.hours_after_service.hours

        if padding_ending.hour == 3 # 9 pm in mexico city
          padding_ending -= 1
        end

        correct_service_schedules(padding_beginning, padding_ending, service, 'padding')
      end

      puts "#{SCHEDULES_CORRECTED.size} schedules corrected "
      puts "#{SCHEDULES_IN_OTHER_SERVICE.size} schedules_in_other_service "
    end


  end
end
