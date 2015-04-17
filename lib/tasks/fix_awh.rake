namespace :db do
  desc "Add padding to schedules"
  task :add_padding_to_schedules => :environment do
	
    20.times do
      failed_schedules = {}
      Aliada.find(39).aliada_working_hours.each do |i|
        awh = AliadaWorkingHour.find i
        begin
          awh.create_schedules_until_horizon
        rescue => exception
          failed_schedules[awh.id] = exception.message.split(' ')[1]
        end
      end

      failed_schedules.each do |key, value|
        s = Schedule.find value
        s.update_attribute(:recurrence_id, key)
      end
    end

  end
end
