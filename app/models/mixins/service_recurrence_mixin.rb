# -*- encoding : utf-8 -*-
module Mixins
  module ServiceRecurrenceMixin

    # To build schedules we must know where do we start
    # because services are booked at an specific range
    def requested_schedules
      ScheduleInterval.build_from_range(datetime, ending_datetime, elements_for_key: estimated_hours, conditions:{ aliada_id: aliada_id })
    end

    def ending_datetime
      datetime + estimated_hours.hours + hours_after_service.hour
    end

    def extras_hours
      extras.inject(0){ |hours,extra| hours += extra.hours || 0 }
    end

    def estimated_hours_without_extras
      (estimated_hours || 0) - extras_hours
    end

    def estimated_hours_with_extras
      (estimated_hours || 0) + extras_hours
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
  end
end

