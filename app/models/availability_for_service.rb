class AvailabilityForService
  include Mixins::AvailabilityFindersMixin
  include AliadaSupport::DatetimeSupport
  attr_reader :report

  def initialize(service, available_after, aliada_id: nil)
    @service = service
    @zone = service.zone
    @available_after = available_after
    @is_recurrent = service.recurrent?
    @aliada_id = aliada_id

    @requested_service_hours = service.estimated_hours
    @minimum_service_hours = @requested_service_hours + Setting.padding_hours_between_services - 1 # we can have a service with 1 hour padding
    @maximum_service_hours = @requested_service_hours + Setting.padding_hours_between_services # or two

    @requested_schedules = @service.requested_schedules # Non persisted schedules
    @first_requested_schedule = @requested_schedules.first

    # skip aliadas we detected cannot fulfill the service
    # User banned aliadas
    @aliadas_to_skip =  @service.user.banned_aliadas.map(&:id)
    
    # Recurrence
    if @is_recurrent
      @recurrency_seconds = service.periodicity.days
      @minimum_availaibilites = service.wdays_count_to_end_of_recurrency(@available_after)
    end

    initialize_trackers

    load_schedules

    enable_service_schedules
  end


  def self.find_aliadas_availability(service, available_after, aliada_id: nil)
    finder = AvailabilityForService.new(service, available_after, aliada_id: aliada_id)
    availability = finder.find
    availability
  end

  # It will try to bind as many aliada_availabilities that matches the requested hours
  # on the same week day per aliada
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

      if is_available? && is_continuous? && time_matches?
        add_continuous_schedules

        store! if enough_continuous_schedules?
      else
        restart_continues_schedules
      end

    end

    clear_incomplete_availabilites
    clear_not_enough_availabilities
    restore_service_schedules_original_state
    mark_padding_hours

    @report.push({message: 'Not found any availability'}) if @aliadas_availability.empty?
    @aliadas_availability
  end

  private

    def store!
      if @is_recurrent && broken_continous_intervals?
        # If we dont have a perfect recurrence we have nothing
        remove_aliada_availability!
        skip_aliada!
        return false
      end

      add_next_schedules_availability

      if @continuous_schedules.size > @maximum_service_hours
        restart_continues_schedules
      end
    end

    def restart_continues_schedules
      @continuous_schedules = []
      # The schedule that just blew up our continuous_schedules might start another so
      # lets start by adding it only if matches
      add_continuous_schedules if is_available? && time_matches?
    end

    def invalid?
      invalid = @schedules.blank? || @requested_schedules.empty? || @schedules.size < @requested_service_hours

      @report.push('Invalid, impossible to proceed') if invalid

      invalid
    end

    def time_matches?
      if @is_recurrent
        @requested_schedules.include_recurrent?(@current_schedule)
      else
        @requested_schedules.include_datetime?(@current_schedule)
      end
    end

    def remove_aliada_availability!
      interval_key = wday_hour(@continuous_schedules)

      @aliadas_availability[@current_aliada_id].delete(interval_key)
    end

    # To track if our schedules are padding
    def mark_padding_hours
      return if @aliadas_availability.blank?

      @aliadas_availability.each do |aliada_id, wday_hour_intervals|
        wday_hour_intervals.each do |wday_hour, intervals_hash|
          intervals_hash.each do |interval_key, interval|
            if interval.size > @requested_service_hours
              padding = interval.size.to_i - @requested_service_hours.to_i

              interval[padding * -1..-1].map(&:as_padding)
            end
          end
        end
      end
    end

    # Remove the availability without the first requested hour
    def clear_incomplete_availabilites
      return if @aliadas_availability.blank?

      @aliadas_availability.delete_if do |aliada_id, wday_hour_intervals|
        wday_hour_intervals.delete_if do |wday_hour, intervals_hash|
          delete = true
          intervals_hash.each do |interval_key, interval|
            next if !delete

            if @is_recurrent 
              delete = !interval.include_recurrent?(@first_requested_schedule)
            else
              delete = !interval.include_datetime?(@first_requested_schedule)
            end
          end

          @report.push({message: "Clearing interval without the first requested schedule", objects: [intervals_hash]}) if delete

          delete
        end

        wday_hour_intervals.blank?
      end
    end
end
