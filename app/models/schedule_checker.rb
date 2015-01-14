class ScheduleChecker

  attr_accessor :starting_datetime, :recurrent, :periodicity, :week_day, :service, :schedule_intervals

  def initialize(service)
    @starting_datetime = service.starting_datetime
    @recurrent = service.service_type.name == 'recurrent'
    @periodicity = service.service_type.periodicity
    @week_day = service.week_day
    @service = service
    @schedule_intervals = build_schedule_intervals
  end

  def possible?
    true
  end

  private
    def build_schedule_intervals
      if recurrent
        recurrence = Recurrence.new(starting_datetime: starting_datetime, periodicity: periodicity)
        recurrence.to_schedule_intervals(service.total_hours)
      else
        [ScheduleInterval.build_from_range(service.start_datetime, service.end_datetime)]
      end
    end

    def datetime_list
      dates = []
      @schedule_intervals.each do |schedule_intervals|
        schedule_interval.schedules.each do |schedule|
          # We floor to the hour because the schedules are set to exact hours too
          dates.push schedule.datetime.beginning_of_hour
        end
      end
      dates
    end
     
    # It will try to build as many schedules intervals that matches the requested hours
    # on the same week day per aliada
    #
    # Receives
    # available_schedules: persisted available schedules ordered by aliada_id, datetime
    # schedule_interval: a proposed interval that should fit 
    #
    # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
    def self.check_datetimes(available_schedules, requested_schedule_interval)
      return false if available_schedules.empty? || 
                      requested_schedule_interval.empty? || 
                      available_schedules.size < requested_schedule_interval.size

      #
      # Set a default array to store our available schedule intervals
      available_for_booking = Hash.new{ |h,k| h[k] = [] }

      requested_starting_datetime = requested_schedule_interval.beginning_of_interval
      requested_ending_datetime = requested_schedule_interval.ending_of_interval

      # It will hold schedules that are time consecutive growing in size
      # until the desired size of schedule is matched
      continues_schedules = []

      # Track schedules in pairs to see if they are continuous 
      previous_schedule = available_schedules.first

      # Because the schedules are sorted we can safely asume that if one of
      # the schedules doesnt match, none will for this aliada so we track it
      banned_aliada_id = nil

      # We could use each_with_index but thats a generated on the fly method
      # and thats really slow
      available_schedules.each do |schedule|
        current_aliada_id = schedule.user_id

        if banned_aliada_id == current_aliada_id
          next
        end

        if continues_schedules.empty?
          # We can't start a continuity without at least one schedule
          continues_schedules.push(schedule)
          # Keep tracking 
          previous_schedule = schedule
          next
        end

        # Do we have a pair of continues schedules?
        # belonging to the same aliada_id?
        # and within our wanted interval range?
        # on the same week day?
        if (schedule.datetime - previous_schedule.datetime) == 1.hour && 
            schedule.aliada_id == previous_schedule.aliada_id &&
            schedule.datetime.hour >= requested_starting_datetime.hour &&
            schedule.datetime.hour <= requested_ending_datetime.hour &&
            schedule.datetime.wday == requested_starting_datetime.wday

          continues_schedules.push(schedule)
        else
          # We don't want to eliminate the start of a potential continuity
          if continues_schedules.size > 1
            # We lost our continuity, so reset our temporary list
            continues_schedules = []

            # Since our schedules are sorted by aliada and datetime we can safely asume that this
            # aliada won't have schedules available again
            banned_aliada_id = current_aliada_id
          end
        end
        
        # If we build enough continues schedules SUCCESS!
        # we found availability, save it
        if continues_schedules.size == requested_schedule_interval.size
          available_schedule_interval = ScheduleInterval.new(continues_schedules, aliada_id: current_aliada_id)

          if available_schedule_interval.valid?
            available_for_booking[current_aliada_id].push(available_schedule_interval)
          end

          # We can safely asume we won't find more with this aliada
          banned_aliada_id = current_aliada_id
          # Start a new succession
          continues_schedules = []
        end

        previous_schedule = schedule
      end
      
      available_for_booking

    end
end
