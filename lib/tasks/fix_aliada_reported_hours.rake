# -*- coding: utf-8 -*-

namespace :db do
  desc "Getting busy the aliadas schedules"
  task :fix_aliada_reported_hours => :environment do
    services = Service.all.each do |service|
      puts "Updating service #{service.id}"
      if service.bill_by_reported_hours?
        service.billable_hours = service.reported_hours
        service.billed_hours = 0 if !service.paid?
        service.save!
      end

      if service.bill_by_billable_hours? 
        if service.paid?
          service.billed_hours = service.billable_hours 
        else
          service.billed_hours = 0
        end
        service.save!
      end
    end
  end
end
