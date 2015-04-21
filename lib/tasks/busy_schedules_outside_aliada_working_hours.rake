namespace :db do
  desc "Busy schedules outside aliada workin hours"
  task :busy_schedules_outside_aliada_working_hours => :environment do
    valid_schedules_ids = []
    missing_schedules = []
	  AliadaWorkingHour.all.each do |awh|

      starting_datetime = awh.next_recurrence_with_hour_now_in_utc

      awh_days = awh.wdays_until_horizon(awh.wday, starting_from: starting_datetime)

      awh_days.times do |i|
        schedule = Schedule.find_by(aliada_id: awh.aliada_id, datetime: starting_datetime)

        if schedule
          valid_schedules_ids.push(schedule.id)
        else
          missing_schedules.push(schedule)
        end

        starting_datetime += awh.periodicity.days
      end
    end

    all_schedules_ids = Schedule.in_the_future.all.pluck(:id)

    invalid_schedules = all_schedules_ids - valid_schedules_ids

    invalid_schedules.map { |s| Schedule.find(s).update_attributes(status: 'busy') }
  end
end
