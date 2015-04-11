namespace :db do
  desc "Add padding to schedules"
  task :add_padding_to_schedules => :environment do
    puts "Padding count #{ Schedule.padding.count }"
    ActiveRecord::Base.transaction do
      no_padding = 0
      padding_1 = 0
      ok = 0
      Service.from_today_to_the_future.all.each do |service|
        user_id = service.user_id
          
        service_ending_datetime = service.datetime + service.estimated_hours.floor.hours
        padding_ending_datetime = service_ending_datetime + 1.hours

        first_schedule_in_front = Schedule.where(datetime: service_ending_datetime).where(aliada_id: service.aliada_id).first
        second_schedule_in_front = Schedule.where(datetime: padding_ending_datetime).where(aliada_id: service.aliada_id).first

        schedules_in_front = [first_schedule_in_front, second_schedule_in_front]


        if first_schedule_in_front && 
           first_schedule_in_front.service_id != service.id && 
           first_schedule_in_front.booked? 
           first_schedule_in_front.busy? 

          first_schedule_in_front.blocked = true
        end

        if second_schedule_in_front && 
           second_schedule_in_front.service_id != service.id && 
           second_schedule_in_front.booked? 
           second_schedule_in_front.busy? 

          second_schedule_in_front.blocked = true
        end

        if first_schedule_in_front.nil?
          padding = 0
          ok += 1
        elsif second_schedule_in_front.nil?
          padding = 1
          ok += 1
        elsif first_schedule_in_front.blocked
          error = "El servicio tiene no tiene horas de colchón con el siguiente"

          Ticket.create_warning(relevant_object: service, message: error, category: 'padding_missing')
          no_padding += 1
          first_schedule_in_front.update(status: 'padding', service_id: service.id, recurrence_id: service.recurrence_id, user_id: user_id)

          padding = 0
        elsif second_schedule_in_front.blocked
          error = "El servicio tiene solo 1 hora de colchón con el siguiente"

          Ticket.create_warning(relevant_object: service, message: error, category: 'padding_missing')
          second_schedule_in_front.update(status: 'padding', service_id: service.id, recurrence_id: service.recurrence_id, user_id: user_id)
          padding_1 += 1
          padding = 1
        else
          padding = 2
          schedules_in_front.each do |schedule|
            schedule.update(status: 'padding', service_id: service.id, recurrence_id: service.recurrence_id, user_id: user_id)
          end
        end

        service.hours_after_service = padding
        begin
          service.save!
        rescue
          error = "El servicio no tiene usuario"
          Ticket.create_warning(relevant_object: service, message: error, category: 'service_without_user')
        end

        if service.schedules.count < service.estimated_hours
          error = "Servicio con insuficientes horas de servicio, estimado para #{service.estimated_hours} y apartadas #{service.schedules.count}"

          Ticket.create_warning(relevant_object: service, message: error, category: 'service_without_enough_schedules')
        end
      end


      puts "Se encontraron #{ok} servicios con 2 horas libres"
      puts "Se encontraron #{no_padding} servicios pegados e imposible ponerles padding"
      puts "Se encontraron #{padding_1} servicios con una sola hora de padding"
      puts "Padding count #{ Schedule.padding.count }"
    end
  end
end
