module Mixins
  # Commonly used methods in our availability finding classes
  module AvailabilityFindersMixin
    def restart_continues_schedules
      @continuous_schedules = []
      # The schedule that just blew up our continuous_schedules might start another so
      # lets start by adding it
      add_continuous_schedules
    end

    # 1 hour away from each other
    def continuous_schedules?
      last_continuous = @continuous_schedules.last

      # If we are starting a continuity
      return true if last_continuous.blank?

      last_continuous.datetime + 1.hour == @current_schedule.datetime
    end

    def same_aliada?
      last_continuous = @continuous_schedules.last

      # If we are starting a continuity
      return true if last_continuous.blank?

      last_continuous.aliada_id == @current_aliada_id
    end

    def add_continuous_schedules
      @continuous_schedules.push(@current_schedule)
    end

    def skip_aliada!
      @aliadas_to_skip.push(@current_aliada_id)
    end

    def skip_aliada?
      @aliadas_to_skip.include?(@current_aliada_id)
    end

    def track_aliadas_changing
      @previous_aliada_id = @current_aliada_id
    end

    def aliada_changed?
      @previous_aliada_id != @current_aliada_id
    end

    def continuous_schedule_intervals?(previous_interval, current_interval)
      (current_interval - previous_interval) == @recurrency_seconds
    end

    def clear_not_enough_availabilities
      if @aliadas_availability.present? && @minimum_availaibilites.present? 
        @aliadas_availability.delete_if { |aliada_id, aliada_availability| aliada_availability.size < @minimum_availaibilites}
      end
    end
  end
end
