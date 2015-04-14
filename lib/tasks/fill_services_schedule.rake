namespace :db do
  desc "Fill services schedules"
  task :fill_services_schedules => :environment do
    puts 'checking aliadas schedules'
    missing_schedules = []

    schedules_in_other_service = Hash.new{ |h,k| h[k] = [] }
    schedules_created = []

    ActiveRecord::Base.transaction do
      Service.not_canceled.in_the_future.each do |service|
        if service.schedules.count < service.estimated_hours
          beginning = service.datetime
          ending = ( service.datetime + service.estimated_hours.hours ).beginning_of_hour

          if ending.hour == 3 # 9 pm in mexico city
            ending -= 1
          end

          aliada_id = service.aliada_id
             
          Time.iterate_in_hour_steps(beginning, ending).each do |datetime|
            schedule = Schedule.find_or_initialize_by(aliada_id: aliada_id, datetime: datetime)

            if schedule.new_record?
              schedule.service_id = service.id
              schedule.user_id = service.user_id
              schedule.recurrence_id = service.recurrence_id
              schedule.status = 'booked'
              schedule.save!

              schedules_created.push(schedule)
            else
              if service.id != schedule.id
                schedules_in_other_service[service.id].push schedule
                next
              end
            end
          end
        end
      end

      puts "#{schedules_created.size} schedules_created "
      puts "#{schedules_in_other_service.size} schedules_in_other_service "
    end


  end
end
