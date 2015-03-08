module AliadaSupport
  module DatetimeSupport
    def horizon
      Time.zone.now + Setting.time_horizon_days.days
    end

    def next_weekday(weekday)
      Chronic.time_class = Time.zone
      Chronic.parse("next #{weekday}")
    end

    # Optionally counting today not included because as per business rule we cant book an aliada for today
    def wdays_until_horizon(wday, starting_from: Time.zone.now)
      count = 0

      while starting_from < horizon do
        count +=1 if starting_from.wday == wday

        starting_from += 1.day
      end
      count
    end

    # A memoized version that stores all the times week day is 
    # going to repeat before the horizon
    def all_wdays_until_horizon(starting_from)
      wdays = [0,1,2,3,4,5,6]
      @all_wdays ||= wdays.map { |wday| wdays_until_horizon(wday, starting_from: starting_from) }
    end

    # A safe datetime we can start booking services
    # too soon and we won't have enough time to organize the aliadas
    def starting_datetime_to_book_services
      tomorrow = (Time.zone.now + 1.day ).beginning_of_day
      in_two_days = tomorrow + 1.day

      Time.zone.now.hour < Setting.booking_for_tomorrow_limit ? tomorrow : in_two_days
    end

    def businesshours_until_horizon
      businessday_hours = Setting.end_of_aliadas_day - Setting.beginning_of_aliadas_day 
      days_until_horizon = (horizon - Time.zone.now)/24.hours

      (businessday_hours * days_until_horizon).round
    end
  end
end
