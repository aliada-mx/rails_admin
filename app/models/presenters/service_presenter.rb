module Presenters
  module ServicePresenter
    def status_enum
      Service::STATUSES
    end

    def user_link
      host = Setting.host
      url = RailsAdmin::Engine.routes.url_helpers.edit_url(user.class, user, host: host)
      name = "(#{user.id}) #{ user.name }"

      ActionController::Base.helpers.link_to(name, url)
    end

    def friendly_datetime
      I18n.l(datetime.in_time_zone(timezone), format: :future) if datetime
    end

    def friendly_time
      I18n.l(datetime.in_time_zone(timezone), format: :friendly_time) if datetime
    end

    def day
      datetime.in_time_zone(timezone).strftime('%d') if datetime
    end

    attr_writer :date
    def date
      if datetime.present?
        datetime.in_time_zone(timezone).strftime('%Y-%m-%d')
      else
        @date
      end
    end

    attr_writer :time
   def time
      if datetime.present?
        datetime.in_time_zone(timezone).strftime('%H:%M') 
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
