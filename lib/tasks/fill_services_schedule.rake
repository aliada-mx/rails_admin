namespace :db do
  desc "Fill services schedules"
  task :fill_services_schedules => :environment do
    puts 'checking aliadas schedules'
    missing_schedules = []


    ActiveRecord::Base.transaction do
      recurrence = Recurrence.find 2935

      schedules_in_other_service = Hash.new{ |h,k| h[k] = [] }
      schedules_corrected = []
      recurrence.services.not_canceled.in_the_future.each do |service|
        if service.schedules.count < service.total_hours
          beginning = service.datetime
          total_hours = service.total_hours.hours
          ending = ( service.datetime + total_hours ).beginning_of_hour

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
