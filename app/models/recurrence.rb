class Recurrence < ActiveRecord::Base
  OWNERS = [
    'aliada',
    'user'
  ]
  include AliadaSupport::DatetimeSupport

  validates_presence_of [:weekday, :hour]
  validates :weekday, inclusion: {in: Time.weekdays.map{ |days| days[0] } }
  validates :hour, inclusion: {in: [*0..23] } 
  validates_numericality_of :periodicity, greater_than: 1

  belongs_to :user
  belongs_to :aliada
  belongs_to :zone

  default_scope { where(owner: 'user') }

  def owner_enum
    OWNERS
  end

  def wday
    Time.weekdays.select{ |day| day[0] == weekday }.first.second
  end

  def get_ending_datetime
    Time.zone.now + Setting.time_horizon_days.day
  end

  # Returns the datetime for the next service
  def next_datetime
    if Time.zone.now.wday == weekday
      Time.zone.now.change(hour: hour)
    else
      next_weekday(weekday).change(hour: hour)
    end
  end

  # Turn the recurrence into an array of schedule intervals
  # optionally creating them on db if they dont exist
  def to_schedule_intervals(schedule_interval_seconds_long, conditions: {})
    beginning_of_schedule_interval = next_datetime
    end_of_schedule_interval = beginning_of_schedule_interval + schedule_interval_seconds_long

    ending_datetime = get_ending_datetime

    schedule_intervals = []
    while end_of_schedule_interval < ending_datetime do
      schedule_interval = ScheduleInterval.build_from_range(beginning_of_schedule_interval, end_of_schedule_interval, conditions: conditions)

      schedule_intervals.push(schedule_interval)

      beginning_of_schedule_interval += periodicity.days
      end_of_schedule_interval += periodicity.days
    end

    schedule_intervals
  end

  rails_admin do
    label_plural 'recurrencias'
    navigation_label 'Operación'
    navigation_icon 'icon-repeat'

    configure :owner do
      visible false
    end
  end
end
