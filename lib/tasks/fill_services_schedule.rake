namespace :db do
  desc "Fill services schedules"
  task :fill_services_schedules => :environment do
    puts 'checking aliadas schedules'
    missing_schedules = []

    schedules_in_other_service = Hash.new{ |h,k| h[k] = [] }
    schedules_corrected = []

    ActiveRecord::Base.transaction do
      Service.not_canceled.in_the_future.each do |service|
        if service.schedules.count < service.estimated_hours
          beginning = service.datetime
          ending = ( service.datetime + service.estimated_hours.hours + service.hours_after_service ).beginning_of_hour

          if ending.hour == 3 # 9 pm in mexico city
            ending -= 1
          end

          aliada_id = service.aliada_id
             
          Time.iterate_in_hour_steps(beginning, ending).each do |datetime|
            schedule = Schedule.find_by(aliada_id: aliada_id, datetime: datetime)

            if schedule 
              if schedule.service_id && service.id != schedule.service_id
                schedules_in_other_service[service.id].push schedule
                next
              else
                puts "https://aliada.mx/aliadadmin/service/#{service.id}"
                puts "https://aliada.mx/aliadadmin/schedule/#{schedule.id}"

                schedule.service_id = service.id
                schedule.user_id = service.user_id
                schedule.recurrence_id = service.recurrence_id
                schedule.status = 'booked'
                schedule.save!
                schedules_corrected.push(schedule)
              end
            end
          end
        end
      end

      puts "#{schedules_corrected.size} schedules corrected "
      puts "#{schedules_in_other_service.size} schedules_in_other_service "
    end


  end
end
