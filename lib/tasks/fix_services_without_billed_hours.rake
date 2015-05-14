namespace :db do
  desc "Fix services without billed hours"
  task :fix_services_without_billed_hours => :environment do
	  Service.where(billed_hours: [ nil, 0 ]).where(status: 'paid').each do |service|

      service.billed_hours = if service.hours_worked && !service.hours_worked.zero?
                               service.hours_worked
                             elsif service.billable_hours && !service.billable_hours.zero?
                               service.billable_hours 
                             elsif service.estimated_hours
                               service.estimated_hours 
                             else 
                               0
                             end
      service.save!
    end
  end
end
