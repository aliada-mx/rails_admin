namespace :db do
  desc "Fixing operations cases "
  task :fix_case => :environment do
    case_name = ENV['CASE_NAME']
    
    puts "fixing #{case_name}"
    case case_name
      when 'recurrencias de diego arvizu'
        user = User.find 673
        wednesday_recurrence_with_friday_services = Recurrence.find 2317
        
        wednesday_recurrence_with_friday_services.weekday = 'friday'

        wednesday_recurrence_with_friday_services.save!

        base_service = Service.find 1672

        base_service.created_at -= 1.week
        
        base_service.save!

        service = Service.find 2187
        service.service_type = ServiceType.one_time_from_recurrent
        service.save!
      when 'gizela recurrence'
        user = User.find 510

        thursday_recurrence = Recurrence.create!(user: user,
                                                 status: 'active', 
                                                 hour: 15,
                                                 periodicity: 7,
                                                 total_hours: 6,
                                                 aliada_id: 17,
                                                 weekday: 'thursday')

        tuesday_recurrence = Recurrence.create!(user: user,
                                                status: 'active', 
                                                hour: 15,
                                                total_hours: 6,
                                                aliada_id: 17,
                                                periodicity: 7,
                                                weekday: 'tuesday')

        user.services.all.each do |service|
          if service.datetime.in_time_zone('Etc/GMT+6').weekday == 'thursday'
            service.recurrence = thursday_recurrence
          end

          if service.datetime.in_time_zone('Etc/GMT+6').weekday == 'tuesday'
            service.recurrence = tuesday_recurrence
          end

          service.save!
        end
      when 'paulina bravo' 
        user = User.find 515

        thursday_recurrence = Recurrence.create!(user: user,
                                                 status: 'active', 
                                                 hour: 8,
                                                 periodicity: 7,
                                                 total_hours: 3,
                                                 aliada_id: 17,
                                                 weekday: 'thursday')


        user.services.all.each do |service|
          if service.datetime.in_time_zone('Etc/GMT+6').weekday == 'thursday'
            puts "found service service id #{service.id} recurrence id #{service.recurrence_id} service type #{service.service_type.name}"
            service.recurrence_id = 2676
            service.save!
          end

        end
      when 'maria graciela lopez'
        user = User.find 91

        recurrence = Recurrence.create!(user: user,
                                                 status: 'active', 
                                                 hour: 7,
                                                 periodicity: 7,
                                                 total_hours: 3,
                                                 aliada_id: 1,
                                                 weekday: 'friday')


        user.services.all.each do |service|
          if service.datetime.in_time_zone('Etc/GMT+6').weekday == 'friday'
            puts "found service service id #{service.id} recurrence id #{service.recurrence_id} service type #{service.service_type.name}"
            service.recurrence_id = 2682
            service.save!
          end

        end

      end


    end
end
