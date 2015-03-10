module TestingSupport
  module SchedulesHelper
    include AliadaSupport::DatetimeSupport

    def create_one_timer!(starting_datetime, hours: hours, conditions: {}, timezone: 'Mexico City', persist: true)
      starting_datetime = starting_datetime.in_time_zone(timezone)
      ending_datetime = starting_datetime + hours.hour

      interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime, conditions: conditions, timezone: timezone)
      if persist
        interval.persist!
      end
      interval
    end

    def create_recurrent!(starting_datetime, hours: hours, periodicity: periodicity, conditions: {}, timezone: 'Mexico City', persist: true)
      starting_datetime = starting_datetime.in_time_zone(timezone)
      ending_datetime = (Time.zone.now.beginning_of_day + Setting.time_horizon_days.day + 1.day ).in_time_zone(timezone)

      intervals = []
      recurrence_days = wdays_until_horizon(starting_datetime.wday, starting_from: starting_datetime)

      recurrence_days.times do |i|
        intervals.push(create_one_timer!(starting_datetime, hours: hours, conditions: conditions, timezone: timezone, persist: persist))

        starting_datetime += periodicity.day
      end

      intervals
    end
  end
end
