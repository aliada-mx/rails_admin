namespace :db do
  desc "Fill hours worked with reported hours"
  task :fill_hours_worked_with_reported_hours => :environment do

    services_filled = []
    ActiveRecord::Base.transaction do

      Service.where('aliada_reported_begin_time IS NOT NULL AND aliada_reported_end_time IS NOT NULL').where(hours_worked: [nil, 0]).each do |service|
        seconds = service.aliada_reported_end_time - service.aliada_reported_begin_time 
        hours = seconds / 3600


        service.hours_worked = if hours > 0
                                 hours
                               else
                                 0
                               end

        puts "hours #{service.hours_worked}"
        service.save!
        services_filled.push(service)
      end

      puts "services_filled #{services_filled.count}"
    end
  end
end
