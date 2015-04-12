# -*- encoding : utf-8 -*-
module TestingSupport
  module SchedulesHelper
    include AliadaSupport::DatetimeSupport

    def create_one_timer!(starting_datetime, hours: hours, conditions: {}, persist: true)
      ending_datetime = starting_datetime + hours.hour

      interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime, conditions: conditions, elements_for_key: hours)
      if persist
        interval.persist!
      end
      interval
    end

    def create_recurrent!(starting_datetime, hours: hours, periodicity: periodicity, conditions: {}, persist: true)
      intervals = []
      recurrence_days = wdays_until_horizon(starting_datetime.wday, starting_from: starting_datetime)

      recurrence_days.times do |i|
        ending_datetime = starting_datetime + hours.hour

        interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime, conditions: conditions, elements_for_key: hours)
        if persist
          interval.persist!
        end
        
        intervals.push(interval)

        starting_datetime += periodicity.day
      end

      intervals
    end

    def intervals_array_to_schedules_datetimes(intervals_array)
      intervals_array.inject([]){ |schedules, interval| schedules + interval.schedules }.map(&:datetime)
    end
  end
end
