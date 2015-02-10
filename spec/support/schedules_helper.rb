module TestingSupport
  module SchedulesHelper
    def create_one_timer!(starting_datetime, hours: hours, conditions: {})
      ending_datetime = starting_datetime + hours.hour

      interval = ScheduleInterval.build_from_range(starting_datetime, ending_datetime, conditions: conditions)
      interval.persist!
      interval
    end

    def create_recurrent!(starting_datetime, hours: hours, periodicity: periodicity, conditions: {})
      ending_datetime = Time.zone.now + Setting.future_horizon_months.months

      intervals = []
      while starting_datetime < ending_datetime do
        intervals.push(create_one_timer!(starting_datetime, hours: hours, conditions: conditions))

        starting_datetime += periodicity.day
      end
      intervals
    end
  end
end
