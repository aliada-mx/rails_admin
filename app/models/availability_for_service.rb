class AvailabilityForService
  include Mixins::AvailabilityFindersMixin

  def initialize(service, aliada_id: nil)
    @service = service

    @requested_schedule_interval = service.to_schedule_interval
    # Pull the schedules from db
    @available_schedules = Schedule.available_for_booking(service.zone)
    if aliada_id.present?
      @available_schedules = @available_schedules.where(aliada_id: aliada_id)
    end

    @recurrent = @service.recurrent?

    # An object to track our availability
    if @recurrent
      @recurrency_seconds = @service.periodicity.days
      @minimum_availaibilites = @service.days_count_to_end_of_recurrency
    end

    @aliadas_availability = Availability.new

    # Limiting variables
    @requested_starting_hour = @requested_schedule_interval.beginning_of_interval.hour
    @requested_ending_hour = @requested_schedule_interval.ending_of_interval.hour
    @requested_wday = @requested_schedule_interval.beginning_of_interval.wday

    # save time consecutive schedules 
    # until the desired size is reached
    @continuous_schedules = []
     
    # skip aliadas we detected cannot fulfill the service
    # User banned aliadas
    @aliadas_to_skip =  @service.user.banned_aliadas.map(&:id)
  end

  def self.find_aliadas_availability(service, aliada_id: nil)
    AvailabilityForService.new(service, aliada_id: aliada_id).find
  end
     
  # It will try to bind as many aliada_availabilities that matches the requested hours
  # on the same week day per aliada
  #
  # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
  def find
    return @aliadas_availability if invalid?

    @previous_aliada_id = @available_schedules.first.aliada_id

    @available_schedules.each do |schedule|
      @current_schedule = schedule
      @current_aliada_id = @current_schedule.aliada_id

      next if skip_aliada?

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

    def store!
      if @recurrent 
        if broken_continous_intervals?
          # If we dont have a perfect recurrence we have nothing
          remove_aliada_availability!
          skip_aliada!
          track_aliadas_changing
          return false
        else
          add_availability
        end
      elsif allow_to_add_one_timer?
        add_availability
      end

      restart_continues_schedules
    end

    def restart_continues_schedules
      @continuous_schedules = []
      # The schedule that just blew up our continuous_schedules might start another so
      # lets start by adding it
      add_continuous_schedules
    end

    def invalid?
      @available_schedules.empty? || @requested_schedule_interval.empty? || @available_schedules.size < @requested_schedule_interval.size
    end

    # Do we have a pair of continues schedules?
    # belonging to the same aliada_id?
    # and within our wanted interval range?
    # on the same week day?
    def should_add_current_schedule?
      continuous_schedules? && same_aliada? && time_matches?
    end

    def add_availability
      @aliadas_availability.add(@current_aliada_id, @continuous_schedules, @current_aliada_id)
    end

    def time_matches?
      # Inside hour range
      @current_schedule.datetime.hour >= @requested_starting_hour &&
      @current_schedule.datetime.hour <= @requested_ending_hour &&
      @current_schedule.datetime.wday == @requested_wday
    end

    def broken_continous_intervals?
      previous_interval = @aliadas_availability[@current_aliada_id].last

      # The first time there is no previous
      return false if previous_interval.blank?

      current_interval = ScheduleInterval.new(@continuous_schedules)

      !continuous_schedule_intervals?(previous_interval, current_interval)
    end

    def enough_continuous_schedules?
      @continuous_schedules.size == @requested_schedule_interval.size
    end

    def allow_to_add_one_timer?
      @aliadas_availability[@current_aliada_id].size.zero?
    end

    def remove_aliada_availability!
      @aliadas_availability.delete(@current_aliada_id)
    end
end
