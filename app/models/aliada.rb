class Aliada < User
  # We uses this instead of default_scope to be able to override it from the
  # parent class
  def self.default_scope 
    where(role: 'aliada')
  end

  def self.best_for_service(service)
    aliadas_availability = ScheduleChecker.find_aliadas_availability(service)

    if service.recurrent?
      # Filter out the aliadas if the recurrency is broken at some point
      recurrent_every = service.recurrence.periodicity.days

      aliadas_availability = Aliada.filter_broken_recurrency(aliadas_availability, recurrent_every)
    end

    aliada_availability = aliadas_availability.first

    {id: aliada_availability.try(:first), schedules_intervals: aliada_availability.try(:second)}
  end

  def self.filter_broken_recurrency(aliadas_availability, recurrency_days)
    aliadas_availability.each do |aliada_id, available_schedules_intervals|

      previous_schedule_interval = available_schedules_intervals.first
      available_schedules_intervals.each_with_index do |schedule_interval,i|
        next if i == 0

        unless (schedule_interval - previous_schedule_interval) == recurrency_days
          aliadas_availability.delete(aliada_id)
          break
        end

        previous_schedule_interval = schedule_interval
      end
    end

    aliadas_availability
  end

end
