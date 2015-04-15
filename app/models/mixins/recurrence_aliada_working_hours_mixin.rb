module Mixins
  module RecurrenceAliadaWorkingHoursMixin
    STATUSES = [
      ['Activa','active'],
      ['Inactiva','inactive']
    ]

    def status_enum
      STATUSES
    end

    def name
      "#{weekday_in_spanish} de #{hour} a #{ending_hour} (#{id})"
    end

    def next_service
      services.ordered_by_datetime.where('datetime > ?', Time.zone.now).first
    end

    def ending_hour
      hour + total_hours
    end

    def weekday_enum
      Time.weekdays.map {|weekday_trio| [weekday_trio.third, weekday_trio.first]}
    end

    def wday
      Time.weekdays.select{ |day| day[0] == weekday }.first.second
    end

    def weekday_in_spanish
      weekday_to_spanish(weekday)
    end

    def timezone
      'Mexico City'
    end

    def in_dst?
      Time.zone.now.in_time_zone(self.timezone).dst?
    end

    def now_in_timezone
      time_obj = Time.zone.now.in_time_zone(self.timezone)
      if in_dst?
        time_obj += 1.hour
      end
      time_obj
    end

    def weekday_now
      time_obj = now_in_timezone
      time_obj.weekday
    end

    def utc_hour(utc_date)
      Chronic.time_class= ActiveSupport::TimeZone[self.timezone]
      time_obj = Chronic.parse("#{utc_date.strftime('%F')} #{self.hour}")
      if time_obj.dst?
        time_obj += 1.hour
      end
      time_obj.utc.hour
    end

    def utc_weekday(utc_date)
      if self.utc_hour(utc_date) <= 23 and self.utc_hour(utc_date) > 6
        return self.weekday
      else
        return Time.next_weekday self.wday  
      end
    end

    def tz_aware_hour(utc_datetime)
      utc_to_timezone(utc_datetime, self.timezone).hour
    end

    def tz_aware_hour(utc_datetime)
      utc_to_timezone(utc_datetime, self.timezone).weekday
    end

    def friendly_time
      text = ""
      if hour > 13
        text += "#{ hour - 12 }:00 pm"
      else
        text += "#{ hour }:00 am"
      end
    end

    def friendly_weekday_hour_in_spanish
      "#{weekday_in_spanish} a las #{ friendly_time }"
    end

    def next_recurrence_now_in_time_zone
      if self.weekday == now_in_timezone.weekday
        return now_in_timezone
      else
        next_day = now_in_timezone
        while self.wday != next_day.wday
          next_day += 1.day
        end
        return next_day
      end
    end

    def next_recurrence_with_hour_now_in_time_zone
      next_recurrence_now_in_time_zone.change(hour: self.hour)
    end

    def next_recurrence_with_hour_now_in_utc
      time_obj = next_recurrence_with_hour_now_in_time_zone
      if time_obj.dst?
        time_obj += 1.hour
      end
      time_obj.utc
    end

    # TODO: fix
    def next_day_of_recurrence(starting_after_datetime)
      next_day = starting_after_datetime.change(hour: hour)

      while next_day.wday != wday
        next_day += 1.day
      end

      next_day
    end

    # Starting the next recurrence day how many days we'll provide service until the horizon
    def wdays_count_to_end_of_recurrency(starting_after_datetime)
      wdays_until_horizon(wday, starting_from: next_day_of_recurrence(starting_after_datetime))
    end

    def wday_hour
      "#{wday} #{hour}"
    end

    def base_service
      services.ordered_by_created_at.first
    end

    def service_attributes
      self.attributes.except!('created_at', 'updated_at', 'id', 'periodicity', 'weekday', 'hour', 'status', 'total_hours')
    end

  end
end
