module AliadaSupport
  module DatetimeSupport
    def next_weekday(weekday)
      Chronic.time_class = Time.zone
      Chronic.parse("next #{weekday}")
    end
  end
end
