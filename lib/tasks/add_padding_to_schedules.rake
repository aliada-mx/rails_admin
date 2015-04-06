namespace :db do
  desc "Add padding to schedules"
  task :add_padding_to_schedules => :environment do
    ActiveRecord::Base.transaction do
      Service.all.each do |service|
        user = service.user
          
        ending_datetime = service.ending_datetime
        padding_ending_datetime = ending_datetime + 2.hours

        schedules = Schedule.where('datetime >= ?', ending_datetime)
                            .where('datetime <= ?', padding_ending_datetime)
                            .where(aliada_id: service.id).to_a


        schedules_count = schedules.count

        next if schedules_count.zero? #end of aliada's day

        padding_count = schedules.select { |s| s.padding? }.count

        next if padding_count == 2

        available_count = schedules.select { |s| s.available? }.count

        if available_count == 2
          puts "adding 2 hours padding to service #{service.id}"
          schedules.update_all(status: 'padding', user_id: user.id, recurrence_id: service.recurrence_id)
          service.hours_after_service = 2
        end

        if available_count == 1
          error = "Se encontró un servicio con solo 1 hora de colchón"
          puts error

          Ticket.create_warning(relevant_object: service, message: error)

          schedules.update_all(status: 'padding', user_id: user.id, recurrence_id: service.recurrence_id)
          service.hours_after_service = 1
        end

        booked_count = schedules.select { |s| s.booked? }.count
        if booked_count > 0
          error = "Servicio #{service.id} #{service.name} que acaba #{service.ending_datetime} sin horas de colchón, con #{schedules.map { |s| [s.status, s.datetime] }.flatten} en frente \n"

          puts error

          Ticket.create_warning(relevant_object: service, message: error)
          service.hours_after_service = 0
        end

        service.save!
      end

      raise ActiveRecord::Rollback
    end
  end
end
