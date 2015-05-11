namespace :db do
  desc "Fix aliada working hours"
  task :fix_aliada_working_hours => :environment do
	  AliadaWorkingHour.active.each do |awh|
      awh.create_schedules_until_horizon
    end
  end
end
