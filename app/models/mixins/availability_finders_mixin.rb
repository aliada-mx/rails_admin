module Mixins
  # Commonly used methods in our availability finding classes
  module AvailabilityFindersMixin
    def restart_continues_schedules
      @continuous_schedules = []
      # The schedule that just blew up our continuous_schedules might start another so
      # lets start by adding it
      add_continuous_schedules
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

    def continuous_schedule_intervals?(previous_interval, current_interval)
      (current_interval - previous_interval) == @recurrency_seconds
    end

    def sort_schedules!
      @available_schedules.sort_by! { |schedule| [ schedule.aliada_id, schedule.datetime ] }
    end
  end
end
