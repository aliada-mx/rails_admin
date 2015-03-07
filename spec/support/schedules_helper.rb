module TestingSupport
  module SchedulesHelper
    include AliadaSupport::DatetimeSupport

    def create_one_timer!(starting_datetime, hours: hours, conditions: {})
      ending_datetime = starting_datetime + hours.hour

      interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime, conditions: conditions)
      interval.persist!
      interval
    end

    def create_recurrent!(starting_datetime, hours: hours, periodicity: periodicity, conditions: {})
      ending_datetime = Time.zone.now.beginning_of_day + Setting.time_horizon_days.day + 1.day 

      intervals = []
      recurrence_days = wdays_until_horizon(starting_datetime.wday, starting_from: starting_datetime)

      recurrence_days.times do |i|
        intervals.push(create_one_timer!(starting_datetime, hours: hours, conditions: conditions))

        starting_datetime += periodicity.day
      end

      intervals
    end
  end
end
