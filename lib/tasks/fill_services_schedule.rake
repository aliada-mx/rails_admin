namespace :db do
  desc "Fill services schedules"
  task :fill_services_schedules => :environment do
    puts 'checking aliadas schedules'
    missing_schedules = []

    schedules_in_other_service = Hash.new{ |h,k| h[k] = [] }
    schedules_corrected = []

    ActiveRecord::Base.transaction do
      Service.not_canceled.in_the_future.each do |service|
        if service.schedules.count < service.total_hours
          beginning = service.datetime
          ending = ( service.datetime + service.total_hours.hours ).beginning_of_hour

          if ending.hour == 3 # 9 pm in mexico city
            ending -= 1
          end

          aliada_id = service.aliada_id
             
          puts "for service with datetime #{service.datetime} #{service.id}"
          Time.iterate_in_hour_steps(beginning, ending).each do |datetime|
            schedule = Schedule.find_by(aliada_id: aliada_id, datetime: datetime)

            if schedule 
              if schedule.service_id && service.id != schedule.service_id
                schedules_in_other_service[service.id].push schedule
                next
              else
                puts "adding schedule #{schedule.datetime} #{schedule.id}"

                schedule.service_id = service.id
                schedule.user_id = service.user_id
                schedule.recurrence_id = service.recurrence_id
                schedule.status = 'booked'
                schedule.save!
                schedules_corrected.push(schedule)
              end
            end
          end
          puts "\n"

        end
      end

      puts "#{schedules_corrected.size} schedules corrected "
      puts "#{schedules_in_other_service.size} schedules_in_other_service "
    end


  end
end
