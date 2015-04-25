module Presenters
  module RecurrencePresenter
    def name
      "#{user.first_name} #{weekday_hour_in_spanish} (#{id})"
    end

    def weekday_hour_in_spanish
      "#{weekday_in_spanish} de #{hour} a #{ending_hour}"
    end
  end
end
