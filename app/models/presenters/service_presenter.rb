module Presenters
  module ServicePresenter
    def status_enum
      Service::STATUSES
    end

    def tz_aware_datetime
      if datetime
        _datetime = datetime.in_time_zone(timezone)
        if _datetime.dst?
          _datetime -= 1.hour
        end
      end
    end

    def user_link
      host = Setting.host
      url = RailsAdmin::Engine.routes.url_helpers.edit_url(user.class, user, host: host)
      name = "(#{user.id}) #{ user.name }"

      ActionController::Base.helpers.link_to(name, url)
    end

    def friendly_datetime
      if self.datetime
        I18n.l(tz_aware_datetime, format: :future)
      end
    end

    def friendly_time
      if datetime
        I18n.l(tz_aware_datetime, format: :friendly_time)
      end
    end

    def day
      if datetime
        tz_aware_datetime.strftime('%e')
      end
    end

    def month
      if datetime
        tz_aware_datetime.strftime('%l')
      end
    end

    attr_writer :date
    def date
      if datetime.present?
        tz_aware_datetime.strftime('%Y-%m-%d')
      else
        @date
      end
    end

    attr_writer :time
   def time
      if datetime.present?
        tz_aware_datetime.strftime('%H:%M') 
      else
        @time
      end
    end

    def estimated_hours_without_extras
      (estimated_hours || 0) - extras_hours
    end

    def estimated_hours_with_extras
      (estimated_hours || 0) + extras_hours
    end
    
    def extras_hours
      extras.inject(0){ |hours,extra| hours += extra.hours || 0 }
    end
  end
end
