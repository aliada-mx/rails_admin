class AvailabilityForCalendar
  include Mixins::AvailabilityFindersMixin
  include AliadaSupport::DatetimeSupport

  def initialize(hours, zone, available_after, recurrent: false, periodicity: nil, aliada_id: nil)
    @hours = hours
    @zone = zone
    @available_after = available_after
    @recurrent = recurrent

    # Pull the schedules from db
    @available_schedules = Schedule.available_for_booking(@zone, available_after)
    if aliada_id.present?
      @available_schedules = @available_schedules.where(aliada_id: aliada_id)
    end
    # Eval the query to avoid multiple queries later on thanks to lazy evaluation
    @available_schedules.to_a

    # An object to track our availability
    @aliadas_availability = Availability.new

    @recurrency_seconds = periodicity.days if @recurrent

    # save time consecutive schedules 
    # until the desired size is reached
    @continuous_schedules = []
  end

  def self.find_availability(hours, zone, available_after, recurrent: false, periodicity: nil, aliada_id: nil)
    AvailabilityForCalendar.new(hours, zone, available_after, recurrent: recurrent, periodicity: periodicity).find
  end
     
  # It will try to build as many aliada_availabilities that matches the requested number of hours
  #
  # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
  def find
    return @aliadas_availability if invalid?

    @available_schedules.each do |schedule|
      @current_schedule = schedule
      @current_aliada_id = @current_schedule.aliada_id
      @wday_hour = availability_group_key

      if should_add_current_schedule? 
        # puts "adding continuous schedule #{@current_schedule.datetime}"
        add_continuous_schedules

        store! if enough_continuous_schedules?
      else
        restart_continues_schedules
      end

    end
    
    clear_not_enough_availabilities
    @aliadas_availability
  end

  private

    # Do we have a pair of continues schedules?
    # belonging to the same aliada_id?
    def should_add_current_schedule?
      continuous_schedules? && same_aliada?
    end

    # To track recurrences we use key common unique per week day hour
    # because for the calendar is enough to know there is at least one
    def availability_group_key
      "#{@current_schedule.datetime.wday}_#{@current_schedule.datetime.hour}"
    end

    def store!
      trim_to_size
      # puts "storeing with key #{@wday_hour} the #{@continuous_schedules.first.datetime}"

      if @recurrent 
        if broken_continous_intervals?
          # puts "broken continuity #{@wday_hour} the #{@continuous_schedules.first.datetime}"
          # If we dont have a perfect recurrence we have nothing
          remove_wday_availability!
          return
        end
      end

      add_availability
    end

    def invalid?
       @available_schedules.empty? || @hours.zero? || @available_schedules.size < @hours || @zone.nil?
    end

    def enough_continuous_schedules?
      @continuous_schedules.size >= @hours
    end

    # Because we are building as many as possible at some point
    # the continuous intervals are going to be too many
    def trim_to_size
      # Adjust to the size needed
      if @continuous_schedules.size > @hours
        @continuous_schedules.delete_at(0)
      end
    end

    def add_availability
      @aliadas_availability.add(@wday_hour, @continuous_schedules, @current_aliada_id)
    end

    def broken_continous_intervals?
      current_interval = ScheduleInterval.new(@continuous_schedules)
      previous_interval = @aliadas_availability[@wday_hour].last

      # The first time there is no previous
      return false if previous_interval.blank?

      value = !continuous_schedule_intervals?(previous_interval, current_interval)
      if value
        
        # puts "found broken continuous intervals"
        # puts "previous #{previous_interval.schedules.map { |s| s.datetime }}"
        # puts "current_interval #{current_interval.schedules.map { |s| s.datetime }}"
        # puts " "
      end
      value
    end

    def remove_wday_availability!
      @aliadas_availability.delete(@wday_hour)
    end

    def clear_not_enough_availabilities
      if @aliadas_availability.present? && @recurrent
        wdays_until_horizon = all_wdays_until_horizon(@available_after)

        @aliadas_availability.delete_if do |aliada_id, aliada_availability| 
          minimum_availabilities = wdays_until_horizon[aliada_availability.first.wday]
          # puts "minimum_availabilities #{minimum_availabilities} vs aliada_availability #{aliada_availability.size}"

          aliada_availability.size < minimum_availabilities
        end
      end
    end
    
    # 1 hour away from each other
    def continuous_schedules?
      last_continuous = @continuous_schedules.last

      # If we are starting a continuity
      return true if last_continuous.blank?

      last_continuous.datetime + 1.hour == @current_schedule.datetime
    end
end
