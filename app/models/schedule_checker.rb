class ScheduleChecker

  def initialize(service)
    if service.recurrent?
      @requested_schedule_interval = service.to_schedule_intervals.first
    else
      @requested_schedule_interval = service.to_schedule_interval
    end
    @available_schedules = Schedule.available_for_booking(service.zone)

    # Set a default array to store the return value of this function
    @available_for_booking = Hash.new{ |h,k| h[k] = [] }

    # Limiting variables
    @requested_starting_hour = @requested_schedule_interval.beginning_of_interval.hour
    @requested_ending_hour = @requested_schedule_interval.ending_of_interval.hour
    @requested_wday = @requested_schedule_interval.beginning_of_interval.wday

    # save time consecutive schedules 
    # until the desired size is reached
    @continuity = []
  end

  def invalid?
    @available_schedules.empty? || @requested_schedule_interval.empty? || @available_schedules.size < @requested_schedule_interval.size
  end

  def self.find_aliadas_availability(service)
    ScheduleChecker.new(service).match_schedules
  end
     
  # It will try to build as many schedules intervals that matches the requested hours
  # on the same week day per aliada
  #
  # Receives
  # available_schedules: persisted available schedules ordered by aliada_id, datetime
  # schedule_interval: a proposed interval that should fit 
  #
  # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
  def match_schedules
    return false if invalid?

    @available_schedules.each do |schedule|
      @current_schedule = schedule
      @current_aliada_id = @current_schedule.aliada_id

      if @continuity.empty?
        # We can't start a continuity without at least one schedule
        # lets save it if its within range hours
        if time_matches?
          increase_continuity
        end
         
        # No point in comparing the schedule with itself
        next
      end

      if valid_continuity?
        increase_continuity
      else
        reset_continues_schedules
      end
      
      # If we build enough continues schedules SUCCESS!
      # we found availability, save it
      if enough_continuous_schedules?

        save_continuous

        # And try to start another
        reset_continues_schedules
      end
    end
    
    @available_for_booking
  end

  private
    def reset_continues_schedules
      @continuity = []
    end

    # Do we have a pair of continues schedules?
    # belonging to the same aliada_id?
    # and within our wanted interval range?
    # on the same week day?
    def valid_continuity?
      @last_continuous = @continuity.last

      # There exist a previous schedule we can check with
      @last_continuous.present? &&
      # 1 hour away from each other
      continuous? && 
      same_aliada? &&
      time_matches?
    end

    def save_continuous
      available_schedule_interval = ScheduleInterval.new(@continuity)

      @available_for_booking[@current_aliada_id].push(available_schedule_interval)
    end

    def continuous?
      @last_continuous.datetime + 1.hour == @current_schedule.datetime
    end

    def time_matches?
      # Inside hour range
      @current_schedule.datetime.hour >= @requested_starting_hour &&
      @current_schedule.datetime.hour <= @requested_ending_hour &&
      # Same week day
      @current_schedule.datetime.wday == @requested_wday
    end

    def same_aliada?
      @last_continuous.aliada_id == @current_schedule.aliada_id
    end

    def enough_continuous_schedules?
      @continuity.size == @requested_schedule_interval.size
    end

    def increase_continuity
      @continuity.push(@current_schedule)
    end
end
