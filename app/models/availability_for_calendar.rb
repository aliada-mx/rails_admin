class AvailabilityForService

  def initialize(hours, recurrent: true)
    @hours = hours
    # Pull the schedules from db
    @available_schedules = Schedule.available_for_booking(service.zone)

    # An object to track our availability
    @aliadas_availability = AliadaAvailability.new(service)

    # save time consecutive schedules 
    # until the desired size is reached
    @continuous_schedules = []
     
    # We accumulate availability per day per aliada until the
    # service availability needs are met
    @availabilities = []

    # skip some aliadas we detected cannot fulfill the service
    @aliadas_to_skip = []
  end

  def self.find_aliadas_availability(hours, recurrent: false)
    AvailabilityForCalendar.new(hours, recurrent).find
  end
     
  # It will try to build as many aliada_availabilities that matches the requested number of hours
  #
  # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
  def find
    return false if invalid?

    @previous_aliada_id = @available_schedules.first.aliada_id

    @available_schedules.each do |schedule|
      @current_schedule = schedule
      @current_aliada_id = @current_schedule.aliada_id

      if skip_aliada?
        track_aliadas_changing
        next
      end

      if aliada_changed?
        clear_availabilities
      end

      if valid_current_schedule?
        add_continuous_schedules
      else
        restart_continues_schedules
        track_aliadas_changing
        next
      end
      
      # If we build enough continues schedules
      # we found availability for a day
      if enough_continuous_schedules?

        if recurrent && broken_continous_intervals?
          remove_aliada_availability!
          skip_aliada!
          track_aliadas_changing
          next
        end

        add_availabilities

        restart_continues_schedules
      end

      track_aliadas_changing
    end
    
    @aliadas_availability
  end

  private
    def restart_continues_schedules
      @continuous_schedules = []
      # The schedule that just blew up our continuous_schedules might start another so
      # lets start by adding it
      add_continuous_schedules
    end

    def invalid?
      @available_schedules.empty? || @hours.zero? || @available_schedules.size
    end

    # Do we have a pair of continues schedules?
    # belonging to the same aliada_id?
    # and within our wanted interval range?
    # on the same week day?
    def valid_current_schedule?
      @last_continuous = @continuous_schedules.last

      @last_continuous.present? &&
      continuous_schedules? && 
      same_aliada? &&
    end

    def add_availabilities
      @availabilities.push(@continuous_schedules)

      @aliadas_availability.add(@current_aliada_id, @availabilities)

      clear_availabilities
    end

      # 1 hour away from each other
    def continuous_schedules?
      @last_continuous.datetime + 1.hour == @current_schedule.datetime
    end

    def same_aliada?
      value = @last_continuous.aliada_id == @current_aliada_id
      value
    end

    def enough_continuous_schedules?
      @continuous_schedules.size >= hours
    end

    def add_continuous_schedules
      @continuous_schedules.push(@current_schedule)
    end

    def remove_aliada_availability!
      @aliadas_availability.delete(@current_aliada_id)
    end

    def clear_availabilities
      @availabilities = []
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

    def broken_continous_intervals?
      current_interval = ScheduleInterval.new(@continuous_schedules)
      previous_interval = @aliadas_availability[@current_aliada_id].last

      # The first time there is no previous
      return false if previous_interval.blank?

      !@aliadas_availability.continuous_schedule_intervals?(previous_interval, current_interval, @current_aliada_id)
    end
end
