module Presenters
  module ServicePresenter
    include ActionView::Helpers::NumberHelper

    def status_enum
      Service::STATUSES
    end

    def tz_aware_datetime
      if datetime
        _datetime = datetime.in_time_zone(timezone)
        if _datetime.dst?
          _datetime -= 1.hour
        end
        _datetime
      end
    end

    def user_link
      host = Setting.host
      url = RailsAdmin::Engine.routes.url_helpers.edit_url(user.class, user, host: host)
      name = "(#{user.id}) #{ user.name }"

      ActionController::Base.helpers.link_to(name, url)
    end

    def friendly_datetime
      I18n.l(tz_aware_datetime, format: :future) if datetime
    end

    def friendly_time
      I18n.l(tz_aware_datetime, format: :friendly_time) if datetime
    end

    def friendly_date
      I18n.l(tz_aware_datetime, format: :friendly_date) if datetime
    end

    def day
      if datetime
        tz_aware_datetime.strftime('%e')
      end
    end

    def month_number
      if datetime
        number_to_human tz_aware_datetime.strftime('%m')
      end
    end

    def month_number
      if datetime
        number_to_human tz_aware_datetime.strftime('%m')
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

    def instructions_summary(truncate)
      instructions_fields = [:entrance_instructions,
        :special_instructions, 
        :cleaning_supplies_instructions, 
        :garbage_instructions,
        :attention_instructions,
        :equipment_instructions,
        :forbidden_instructions, ] 

      summary_values = instructions_fields.inject([]) do |values, field_name|
        value = self.send(field_name)
        values.push value if value.present?
        values
      end

      if summary_values.any? { |value| value.present? }
        summary_values.join(', ')[0..truncate]+"..."
      else
        'No has dejado instrucciones'
      end
    end

    def weekday_in_spanish
      tz_aware_datetime.dia_semana
    end
  end
end
