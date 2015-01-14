class Recurrence < ActiveRecord::Base
  include Aliada::GeneralHelpers::DatetimeSupport

  belongs_to :user

  validates_presence_of :user

  def day_of_week
    starting_datetime.try(:wday)
  end

  def hour
    starting_datetime.try(:hour)
  end

  def ending_datetime
    Time.zone.now + Setting.future_horizon_months.months
  end

  # Turn the recurrence into an array of not-persisted-in-db schedule intervals
  def to_schedule_intervals(schedule_interval_hours_size)
    schedule_intervals = []
    current_datetime = starting_datetime

    while current_datetime < ending_datetime do
      end_of_schedule_interval = current_datetime + schedule_interval_hours_size

      schedule_intervals.push(ScheduleInterval.build_from_range(current_datetime , end_of_schedule_interval))

      current_datetime += periodicity.days
    end
    
    schedule_intervals
  end
end
