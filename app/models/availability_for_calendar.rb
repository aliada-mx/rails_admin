class AvailabilityForCalendar
  include Mixins::AvailabilityFindersMixin
  include AliadaSupport::DatetimeSupport

  def initialize(hours, zone ,  recurrent: false, periodicity: nil, aliada_id: nil)
    @hours = hours
    # Pull the schedules from db
    @available_schedules = Schedule.available_for_booking(zone)
    if aliada_id.present?
      @available_schedules = @available_schedules.where(aliada_id: aliada_id)
    end

    # An object to track our availability
    @aliadas_availability = Availability.new

    @recurrent = recurrent
    if @recurrent
      @recurrency_seconds = periodicity.days
      @minimum_availaibilites = recurrences_until_horizon(periodicity)
    end


    # save time consecutive schedules 
    # until the desired size is reached
    @continuous_schedules = []
  end

  def self.find_availability(hours, recurrent: false)
    AvailabilityForCalendar.new(hours, recurrent).find
  end
     
  # It will try to build as many aliada_availabilities that matches the requested number of hours
  #
  # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
  def find
    return @aliadas_availability if invalid?

    @previous_aliada_id = @available_schedules.first.aliada_id

    @available_schedules.each do |schedule|
      @current_schedule = schedule
      @current_aliada_id = @current_schedule.aliada_id
      @wday_hour = availability_group_key

      if should_add_current_schedule? 
        add_continuous_schedules

        store! if enough_continuous_schedules?
      else
        restart_continues_schedules
      end

      track_aliadas_changing
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

      if @recurrent 
        if broken_continous_intervals?
          # If we dont have a perfect recurrence we have nothing
          remove_aliada_availability!
          track_aliadas_changing
          return
        end
      end

      add_availability
    end

    def invalid?
      @available_schedules.empty? || @hours.zero? || @available_schedules.size < @hours
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

      !continuous_schedule_intervals?(previous_interval, current_interval)
    end

    def remove_aliada_availability!
      @aliadas_availability.delete(@wday_hour)
    end
end
