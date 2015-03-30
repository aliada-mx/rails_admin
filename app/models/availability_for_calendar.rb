class AvailabilityForCalendar
  include Mixins::AvailabilityFindersMixin
  include AliadaSupport::DatetimeSupport

  attr_reader :report

  def initialize(requested_hours, zone, available_after, recurrent: false, periodicity: nil, aliada_id: nil, service: nil)
    @service = service
    @zone = zone
    @available_after = available_after
    @is_recurrent = recurrent
    @aliada_id = aliada_id
    @periodicity = periodicity

    @requested_service_hours = requested_hours
    @minimum_service_hours = @requested_service_hours + Setting.padding_hours_between_services - 1 # we can have a service with 1 hour padding
    @maximum_service_hours = @requested_service_hours + Setting.padding_hours_between_services # or two

    @recurrency_seconds = @periodicity.days if @is_recurrent

    if @service.present?
      @aliadas_to_skip =  @service.user.banned_aliadas.map(&:id)
    else
      @aliadas_to_skip =  []
    end

    initialize_trackers

    load_schedules

    enable_service_schedules
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
    availability
  end
     
  # It will try to build as many aliada_availabilities that matches the requested number of service_hours
  #
  # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
  def find
    return @aliadas_availability if invalid?

    @schedules.each_with_index do |schedule,index|
      @current_schedule = schedule
      @current_aliada_id = schedule.aliada_id
      @current_index = index
      @current_schedule.index = index

      next if skip_aliada?
      next if index_already_checked

      if is_available? && is_continuous? 
        add_continuous_schedules

        store! if enough_continuous_schedules?
      else
        restart_continues_schedules
      end

    end

    clear_not_enough_availabilities
    restore_service_schedules_original_state
    @aliadas_availability
  end

  private

    def restart_continues_schedules
      @continuous_schedules = []
      # The schedule that just blew up our continuous_schedules might start another so
      # lets start by adding it
      add_continuous_schedules if is_available?
    end

    def store!
      trim_to_size

      if @is_recurrent && broken_continous_intervals?
        # If we dont have a continous recurrence we have nothing
        remove_wday_availability!
        return
      end

      add_next_schedules_availability
    end

    def invalid?
       invalid = @schedules.blank? || @requested_service_hours.zero? || @schedules.size < @requested_service_hours || @zone.nil?
       @report.push('Invalid, impossible to proceed') if invalid

       invalid
    end

    # Because we are building as many as possible at some point
    # the continuous intervals are going to be too many
    def trim_to_size
      # Adjust to the size needed
      if @continuous_schedules.size > @maximum_service_hours
        @continuous_schedules.delete_at(0)
      end
    end

    def remove_wday_availability!
      interval_key = wday_hour(@continuous_schedules)

      @aliadas_availability[@current_aliada_id].delete(interval_key)
    end

end

