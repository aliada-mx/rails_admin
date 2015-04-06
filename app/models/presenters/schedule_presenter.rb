module Presenters
  module SchedulePresenter

    def name
      I18n.l(datetime, format: :future)
    end

    def tz_aware_datetime
      utc_to_timezone(datetime, timezone)
    end
  end
end
