module AliadaSupport
  module AliadasHelpers
    # As far as Aliada.mx sees
    def horizon
      Time.zone.now + Setting.time_horizon_days.days
    end

    def businesshours_until_horizon
      businessday_hours = Setting.end_of_aliadas_day - Setting.beginning_of_aliadas_day 
      days_until_horizon = (horizon - Time.zone.now)/24.hours

      (businessday_hours * days_until_horizon).round
    end
  end
end
