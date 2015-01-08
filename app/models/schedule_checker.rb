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
    recurrent ? recurrent_possible? : one_time_possible?
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

    def available_schedules
      Schedule.available.in_datetimes(datetime_list)
    end

    def recurrent_possible?
      # @schedule_intervals available_schedules
    end

    def one_time_possible?
      # @schedule_intervals available_schedules
    end

    # Receives
    # available_schedules: persisted available schedules 
    # schedule_interval: a proposed interval that should fit 
    #
    # returns {'aliada_id' => [available_schedule_interval, available_schedule_interval]}
    def self.fits_in_schedules(available_schedules, wanted_schedule_interval)
      return false if available_schedules.empty? || 
                      wanted_schedule_interval.empty? || 
                      available_schedules.size < wanted_schedule_interval.size

      available_per_aliada = ScheduleChecker.unique_per_aliada(available_schedules, wanted_schedule_interval)

      available_for_booking = {}
      available_per_aliada.each do |aliada_id, aliadas_schedules_intervals|
        aliadas_schedules_intervals.each do |aliada_schedule_interval|
          available_for_booking[aliada_id] = aliada_schedule_interval if wanted_schedule_interval.fit_in(aliada_schedule_interval)
        end
      end
      
      available_for_booking
    end

    # Receives
    # available_schedules: persisted available schedules 
    #
    # Returns
    # {'aliada_id' => [schedule_interval, schedule_interval]}
    def self.unique_per_aliada(available_schedules, wanted_schedule_interval)
      unique_aliadas_available_schedules = available_schedules.uniq { |schedule| schedule.aliada_id }

      aliadas_schedules_intervals = {}
      unique_aliadas_available_schedules.each do |schedule|
        aliada_schedules = available_schedules.select { |s| s.aliada_id == schedule.aliada_id }

        aliada_schedules_intervals = ScheduleInterval.extract_from_schedules(aliada_schedules, wanted_schedule_interval.size, aliada: schedule.aliada)

        aliadas_schedules_intervals[schedule.aliada_id] = aliada_schedules_intervals
      end

      aliadas_schedules_intervals
    end
end
