# -*- encoding : utf-8 -*-
module Presenters
  module AliadaPresenter
    def average_score
      scores.average(:value)
    end

    def services_worked
      services.not_canceled.finished.count
    end

    def services_unassigned_this_month
      service_unassignments.where(created_at: this_month_range).count
    end

    def show_unassignment_warning
      services_unassigned_this_month >= Setting.aliada_unassignments_per_month - 1
    end

    def birthday_today?
      if birthday 
        birthday_in_time_zone = birthday.in_time_zone('Mexico City')
        now_in_timezone = Time.zone.now.in_time_zone('Mexico City')
        
        birthday_in_time_zone.month == now_in_timezone.month && birthday_in_time_zone.day == now_in_timezone.day
      end
    end

    def current_week_time_worked
      hours_worked = 0
      minutes_worked = 0

      current_week_services.each do |service|
        if service.hours_worked
          hours_worked += service.hours_worked
        end
        if service.minutes_worked
          minutes_worked += service.minutes_worked 
        end
      end

      if minutes_worked > 60
        hours_worked += minutes_worked / 60
        minutes_text = "#{ minutes_worked % 60 } minutos"
      else
        minutes_text = "#{ minutes_worked } minutos"
      end

      text = "#{hours_worked.to_i} horas" 
      text += ", #{minutes_text}" if minutes_worked > 0
      text
    end
  end
end
