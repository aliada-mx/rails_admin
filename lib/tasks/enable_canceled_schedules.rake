namespace :util do
  desc "Set a day's canceled service's schedules as available"
  task :enable_canceled_service_schedules, [:dia]  => :environment do |t, args|
    day = ActiveSupport::TimeZone['Mexico City'].parse(args[:dia])
    beginning = day.beginning_of_day.utc
    ending = day.end_of_day.utc
    aliadas = args.extras
    
    
    services = Service.where(:aliada_id => aliadas, status: 'canceled',  :datetime => (beginning..ending))
    services.each do |s|
      s.schedules.each do |schedule|
        schedule.status = 'available'
        schedule.save!
      end
    end
  end
end
