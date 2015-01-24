class Aliada < User
  # We uses this instead of default_scope to be able to override it from the
  # parent class
  def self.default_scope 
    where(role: 'aliada')
  end

  def best_for_service(service)
    zone = service.zone
    service_size = service.total_hours

    aliadas_availability = find_availability(service_size, zone)
    schedule_intervals_requested = service.to_schedule_intervals

    determine_aliada(aliadas_availability, service)
  end

  def find_availability(service_size, zone)
    available_schedules = Schedule.available.
                                   in_zone(zone).
                                   in_the_future.
                                   ordered_by_aliada_datetime

    ScheduleChecker.check_datetimes(available_schedules, service_size)
  end

  def determine_aliada(aliadas_availability, service)
    if service.recurrent?
      # Filter out the aliadas if the recurrency is broken
      aliada_availability = ScheduleInterval.filter_broken_recurrency(aliada_availability)
    end

    Hash[*aliadas_availability.first]
  end
end
