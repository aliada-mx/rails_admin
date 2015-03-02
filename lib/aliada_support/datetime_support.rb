module AliadaSupport
  module DatetimeSupport
    def next_weekday(weekday)
      Chronic.time_class = Time.zone
      Chronic.parse("next #{weekday}")
    end

    def recurrences_until_horizon(periodicity)
      current_datetime = Time.zone.now
      ending_datetime = current_datetime + Setting.time_horizon_days.days

      count = 0

      while current_datetime < ending_datetime
        current_datetime += periodicity.days
        count +=1
      end
      count
    end

  end
end
