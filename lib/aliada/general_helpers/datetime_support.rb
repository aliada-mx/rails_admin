module Aliada
  module GeneralHelpers
    module DatetimeSupport
      def next_week
        Time.zone.now + (7 - Time.zone.now.wday)
      end

      def next_weekday(n)
        n > Time.zone.now.wday ? Time.zone.now + (n - Time.zone.now.wday) : self.next_week.next_day(n)
      end
    end
  end
end
