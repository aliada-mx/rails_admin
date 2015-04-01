namespace :db do
  desc "Frees a recurrence's schedules"
  task :enable_recurrence_schedules => :environment do
    
    id = ENV['recurrences_id'] 
    Recurrence.find_by(id: id).services.each do |service|
      service.schedules.each do |schedule|
        schedule.status = 'available'
        schedule.save!
      end
    end
  end
end
