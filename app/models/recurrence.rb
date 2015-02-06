class Recurrence < ActiveRecord::Base
  include AliadaSupport::GeneralHelpers::DatetimeSupport

  validates_presence_of [:weekday, :hour]
  validates :weekday, inclusion: {in: Time.weekdays.map{ |days| days[0] } }
  validates :hour, inclusion: {in: [*0..23] } 

  belongs_to :user
  belongs_to :aliada
  belongs_to :zone

  def wday
    Time.weekdays.select{ |day| day[0] == weekday }.first.second
  end

  def get_ending_datetime
    Time.zone.now + Setting.future_horizon_months.months
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

  def self.fill_schedule
    today_in_the_future = DateTime.now.beginning_of_day + Setting.future_horizon_months.month + 1.day

    # aliada's recurrences, to build the whole availability
    Recurrence.where("user_id is null").each do |aliada_recurrence|
      if today_in_the_future.weekday == aliada_recurrence.weekday 

        schedule_intervals = ScheduleInterval.build_from_range (today_in_the_future + aliada_recurrence.hour.hour), (today_in_the_future + aliada_recurrence.hour.hour + aliada_recurrence.total_hours.hour), from_existing: false, conditions: {aliada_id: aliada_recurrence.aliada_id, zone_id: aliada_recurrence.zone_id, service_id: nil}
        schedule_intervals.persist!
      end
    end

    # client's recurrences, to build services
    Recurrence.where("user_id is not null").each do |user_recurrence|
      if today_in_the_future.weekday == user_recurrence.weekday 

        # Create service with the most recently modified one for that recurrence
        # TODO: modify query with status for inactive recurrences
        services = Service.where("recurrence_id = ?", user_recurrence.id).order("updated_at DESC")
        if services.empty?
          error = "Services have not been created for this user's recurrence"
          Rails.logger.fatal error
          raise error
        end
        service = services.first.dup
        service.datetime = (today_in_the_future + user_recurrence.hour.hour)
        service.save!

        # Find the schedule in which the client will be assigned
        schedules = Schedule.where("aliada_id = ? AND zone_id = ? AND datetime >= ? AND datetime < ?", user_recurrence.aliada_id, user_recurrence.zone_id, (today_in_the_future + user_recurrence.hour.hour),  (today_in_the_future + user_recurrence.hour.hour + user_recurrence.total_hours.hour) )
        if schedules.empty? 
          error = "Aliada's future schedule was not found. Probably, the client's recurrence was not built considering the aliada's recurrence."
          Rails.logger.fatal error
          raise error
        end
        
        # Assign the client to the aliada's schedule
        ScheduleInterval.new(schedules).book_schedules!(aliada_id: user_recurrence.aliada_id, user_id: user_recurrence.user_id, service_id: service.id)
      end
    end
  end
end
