namespace :db do
  desc "Fix services with missing aliadas"
  task :fix_services_with_missing_aliadas => :environment do
    broken_services = Service.where(aliada_id: [0,nil])

    ActiveRecord::Base.transaction do
      puts "#{broken_services.count} broken_services found"
      fixed_services = 0

      broken_services.each do |service|

        if service.recurrence.present?

          fixed_services += 1
          service.aliada_id = service.recurrence.aliada_id
          service.aliada_id
          service.save!
        end
      end

      puts "fixed #{fixed_services} services "

      raise ActiveRecord::Rollback
    end
  end
end
