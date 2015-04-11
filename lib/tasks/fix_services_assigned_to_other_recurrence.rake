namespace :db do
  desc "Fix services assigned to other recurrences"
  task :fix_services_assigned_to_other_recurrence => :environment do

    def create_recurrence_from_service(service)
      Recurrence.create!(user: service.user,
                         status: 'active', 
                         hour: service.tz_aware_datetime.hour,
                         periodicity: 7,
                         total_hours: service.total_hours,
                         aliada_id: service.aliada_id,
                         weekday: service.tz_aware_datetime.weekday)
    end

    ActiveRecord::Base.transaction do

      broken_services = []
      ok_services = {}
      # Recurrent and recurent from one timer services
      User.all.each do |user|

        user.services.all.each do |service|

          if service.recurrence_id.nil? && [1,3].include?( service.service_type_id )
            # puts "found broken service id #{service.id} datetime #{service.tz_aware_datetime} service type #{service.service_type.name} user #{service.user.name}"
            broken_services.push(service)
          end

          if service.recurrence_id.present?
            if ok_services.has_key?(service.user.id) 

              ok_services[service.user.id][service.wday_hour] = service.recurrence
            else

              ok_services[service.user.id] = {service.wday_hour => service.recurrence}
            end
          end

        end
      end

      puts "found #{broken_services.size} broken_services without recurrence"

      created = 0
      broken_services.each do |service|
        service_wday_hour = ok_services[service.user.id]

        if service_wday_hour
          recurrence = ok_services[service.user.id][service.wday_hour]
        end

        if not recurrence
          recurrence = create_recurrence_from_service(service)
          created += 1

          if ok_services.has_key?(service.user.id) 

            ok_services[service.user.id][service.wday_hour] = recurrence
          else

            ok_services[service.user.id] = {service.wday_hour => recurrence}
          end
        end

        service.recurrence = recurrence
        service.save!
      end

      puts "created #{created} recurrences"

      puts "Fixing recurrences without base service"

      fixed_without_base_service = 0
      Service.where(service_type_id: 3).all.each do |service|
        recurrence = service.recurrence
        base_service =  recurrence.base_service

        if base_service.service_type_id != 1
          fixed_without_base_service += 1
          
          base_service.service_type_id = 1
          base_service.save!
        end
      end

      puts "fixed_without_base_service #{fixed_without_base_service}"

    end
  end
end
