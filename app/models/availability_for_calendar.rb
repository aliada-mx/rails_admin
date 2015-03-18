class AvailabilityForCalendar
  include Mixins::AvailabilityFindersMixin
  include AliadaSupport::DatetimeSupport

  attr_reader :report

  def initialize(service_hours, zone, available_after, recurrent: false, periodicity: nil, aliada_id: nil, service: nil)
    @requested_service_hours = service_hours
    @minimum_service_hours = @requested_service_hours + 1 # we can have a service with 1 hour padding
    @maximum_service_hours = @requested_service_hours + 2 # or two
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

    # Inject service schedules
    if service.present?
      @service_schedules = service.schedules.in_the_future
      @available_schedules = @available_schedules + @service_schedules
      # We need to preserve the order respected by our available for booking query
      sort_schedules!
    end

    # An object to track our availability
    @aliadas_availability = Availability.new

    @recurrency_seconds = periodicity.days if @recurrent

    # save time consecutive schedules 
    # until the desired size is reached
    @continuous_schedules = []

    # Track why our availability is missing
    @report = []
  end

  def self.find_availability(service_hours, zone, available_after, recurrent: false, periodicity: nil, aliada_id: nil, service: nil)
    finder = AvailabilityForCalendar.new(service_hours, 
                                         zone,
                                         available_after,
                                         recurrent: recurrent,
                                         periodicity: periodicity,
                                         aliada_id: aliada_id,
                                         service: service)
    availability = finder.find
    # binding.pry
    availability
  end
     
  # It will try to build as many aliada_availabilities that matches the requested number of service_hours
  #
  # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
  def find
    return @aliadas_availability if invalid?

    @available_schedules.each do |schedule|
      @current_schedule = schedule
      @current_aliada_id = @current_schedule.aliada_id

      if should_add_current_schedule? 
        add_continuous_schedules

        store! if enough_continuous_schedules?
      else
        restart_continues_schedules
      end

    end

    clear_not_large_enough_availabilities @zone
    clear_not_enough_availabilities
    @aliadas_availability
  end

  private

    # Do we have a pair of continues schedules?
    # belonging to the same aliada_id?
    def should_add_current_schedule?
      continuous_schedules? && same_aliada?
    end

    # To compare recurrences continuity we must have them unique pero wday hour and aliada
    def continous_schedules_key(continuous_schedules)
      wday_hour_aliada_id =  continuous_schedules.reduce('') do |string, schedule| 
        string += "-#{schedule.datetime.wday}_#{schedule.datetime.hour}_#{schedule.aliada_id}-"
      end
      Digest::MD5.hexdigest(wday_hour_aliada_id)
    end

    def store!
      trim_to_size

      if @recurrent 
        if broken_continous_intervals?
          # If we dont have a continous recurrence we have nothing
          remove_wday_availability!
          return
        end
      end

      add_availability
    end

    def invalid?
       invalid = @available_schedules.blank? || @requested_service_hours.zero? || @available_schedules.size < @requested_service_hours || @zone.nil?
       @report.push('Invalid, impossible to proceed') if invalid

       invalid
    end

    def enough_continuous_schedules?
      @continuous_schedules.size >= @requested_service_hours
    end

    # Because we are building as many as possible at some point
    # the continuous intervals are going to be too many
    def trim_to_size
      # Adjust to the size needed
      if @continuous_schedules.size > @maximum_service_hours
        @continuous_schedules.delete_at(0)
      end
    end

    def add_availability
      interval_key = continous_schedules_key( @continuous_schedules )

      @aliadas_availability.add(interval_key, @continuous_schedules, @current_aliada_id)
    end

    def broken_continous_intervals?
      interval_key = continous_schedules_key( @continuous_schedules )

      current_interval = ScheduleInterval.new(@continuous_schedules, aliada_id: @current_aliada_id)
      previous_interval = @aliadas_availability[interval_key].last

      # The first time there is no previous
      return false if previous_interval.blank?

      value = !continuous_schedule_intervals?(previous_interval, current_interval)

      @report.push({message: 'Found 1 broken recurrent continuity', objects: [previous_interval, current_interval] }) if value

      value
    end

    def remove_wday_availability!
      interval_key = continous_schedules_key( @continuous_schedules )

      @aliadas_availability.delete(interval_key)
    end

    # Because we are building as many as posible we might end up
    # with intevals that are a subset of the next and we
    # want the largest possible
    def clear_redundant
      @aliadas_availability.remove_redundant 
    end

    def clear_not_large_enough_availabilities zone
      return unless @aliadas_availability.present? 

      @aliadas_availability.delete_if do |availability_key, aliada_availability|

        aliada_availability.delete_if do |interval|

          if interval.size == @maximum_service_hours
            keep = true
          else
            free_continuous_hours_in_front = interval.free_continuous_hours_in_front(@zone)

            if interval.size == @requested_service_hours

              keep = free_continuous_hours_in_front == 2
            elsif interval.size == @minimum_service_hours

              keep = free_continuous_hours_in_front >= 1
            end
          end

          !keep
        end

        aliada_availability.empty?
      end
    end

    def clear_not_enough_availabilities
      if @aliadas_availability.present? && @recurrent
        wdays_until_horizon = all_wdays_until_horizon(@available_after)

        @aliadas_availability.delete_if do |availability_key, aliada_availability| 
          next if aliada_availability.first.nil?

          minimum_availabilities = wdays_until_horizon[aliada_availability.first.wday]

          value = aliada_availability.size < minimum_availabilities
          @report.push({message: 'Cleared a too few availability', objects: [minimum_availabilities, aliada_availability] }) if value
          value
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
