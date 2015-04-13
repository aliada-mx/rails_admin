namespace :db do
    desc "Fix services with missing aliadas"
    task :fix_services_with_missing_aliadas => :environment do
        puts 'Fixing services and recurrences with aliada id nil or 0'

        broken_services = Service.where(aliada_id: [0,nil])

        ActiveRecord::Base.transaction do
            puts "#{broken_services.count} broken_services found"
            fixed_services = 0
            still_broken = []

            broken_services.each do |service|

                if service.recurrence.present?

                    aliada_id = service.recurrence.aliada_id
                    
                    if aliada_id.nil? || aliada_id.zero?
                        still_broken.push(service)
                    else
                        service.aliada_id = service.recurrence.aliada_id
                        service.aliada_id
                        service.save!
                        fixed_services += 1
                    end
                end
            end
            puts "fixed #{fixed_services} services with the recurrence"


            puts "trying to fix #{still_broken.size} with the services recurrences aliadas id"
            aliadas_id = {}
            finally_fixed = 0
            still_broken.each do |service|
                service.recurrence.services.each do |_service|
                    if _service.aliada_id != nil && _service.aliada_id != 0 &&
                        service.aliada_id == nil || service.aliada_id.zero?

                        service.aliada_id = _service.aliada_id
                        recurrence = service.recurrence
                        recurrence.aliada_id = _service.aliada_id
                        service.save!
                        recurrence.save!
                        finally_fixed += 1
                    end
                end

            end
            puts "managed to fix #{finally_fixed}"

        end
    end
end
