module Presenters
  module ServicePresenter
    include ActionView::Helpers::NumberHelper

    def status_enum
      Service::STATUSES
    end

    def status_in_spanish
      Hash[*status_enum.flatten].to_h.invert[status]
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

    def name
      name = "#{I18n.l(datetime, format: :future)}"
      name += ", #{address.name}" if address
    end

    def user_link
      rails_admin_edit_link(user)
    end

    def address_map_link
      if address
        if address.map_missing?
          name = "* #{address.name}" 
        else
          name = address.name
        end

        address_map_action_link(address, name: name)
      else
        'Le falta dirección a este servicio '
      end
    end

    def aliada_webapp_link
      aliada_show_webapp_link(aliada)
    end

    def aliada_link
      rails_admin_edit_link(aliada)
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

    def friendly_total_hours
      if bill_by_billable_hours?
       seconds_to_hours_minutes_in_spanish(billable_hours.hours)

      elsif bill_by_reported_hours?
       seconds_to_hours_minutes_in_spanish(reported_hours.hours)

     else
       raise "Faltan horas en friendly total_hours del servicio #{self.id}"
      end
    end

    def extras_hours
      extras.inject(0){ |hours,extra| hours += extra.hours || 0 }
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

    def to_json
      attributes.merge!({amount_to_bill: amount_to_bill})
    end

    def friendly_aliada_reported_begin_time
      if self.aliada_reported_begin_time
        I18n.l self.aliada_reported_end_begin_in_gtm_6, format: '%H:%M %p'
      end
    end

    def friendly_aliada_reported_end_time
      if self.aliada_reported_end_time
        I18n.l self.aliada_reported_end_time_in_gtm_6, format: '%H:%M %p'
      end
    end

    def aliada_reported_end_time_in_gtm_6
      self.aliada_reported_end_time.in_time_zone("Etc/GMT+6")
    end

    def aliada_reported_end_begin_in_gtm_6
      self.aliada_reported_begin_time.in_time_zone("Etc/GMT+6")
    end

    def wday_hour
      "#{tz_aware_datetime.wday} #{tz_aware_datetime.hour}" 
    end
  end
end

