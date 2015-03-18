# Represents a series of unique schedule intervals available by a single or many aliadas
class Availability
  extend Forwardable

  def_delegators :@store, :delete_if, :[], :empty?, :delete, :present?, :each, :has_key?, :first, :second
  def_delegator :@store, :keys, :ids
  def_delegator :@store, :has_key?, :has_aliada?
  attr_accessor :store 
  attr_reader :aliada

  def initialize(aliada: nil)
    # A hash with an array as default value for new keys
    @store = Hash.new{ |h,k| h[k] = [] }
    @aliada = aliada
  end

  def add(availability_key, continuous_schedule, aliada_id)
    new_interval = ensure_schedule_interval!(continuous_schedule, aliada_id: aliada_id)

    @store[availability_key].push(new_interval)
  end

  def ensure_schedule_interval!(continuous_schedule, aliada_id: nil)
    if continuous_schedule.class == ScheduleInterval
      return continuous_schedule
    else
      return ScheduleInterval.new(continuous_schedule, aliada_id: aliada_id)
    end
  end

  def size
    @store.values.size
  end

  def schedules
    @store.values.flatten.map(&:schedules).flatten
  end

  def for_aliada(aliada)
    aliada_availability = Availability.new(aliada: aliada)
    aliada_availability.store = @store.select { |key, intervals| intervals.any?{ |interval| interval.aliada_id == aliada.id }  }
    aliada_availability
  end

  def book(service)
    if schedules_intervals.present? && aliada.present?
      schedules_intervals.each do |schedule_interval|
        schedule_interval.book_schedules(aliada_id: aliada.id, user_id: service.user_id, service_id: service.id)
      end
      service.assign(aliada)
    else
      service.mark_as_missing
    end

    service.save!
  end

  def enable_unused_schedules(service_schedules)
    unused = service_schedules - self.schedules

    unused.each do |schedule|
      schedule.enable_booked
    end
  end

  def schedules_intervals
    @store.values.flatten
  end

  def beginning
    schedules_intervals.first.beginning_of_interval
  end

  # format expected by jquery.calendario
  def for_calendario(timezone, zone)
    # A hash with an array as default value for new keys
    # to get unique datetimes
    dates_times = Hash.new{ |h,k| h[k] = [] }

    schedules_intervals.map do |schedule_interval|
      datetime = schedule_interval.beginning_of_service_interval zone

      date = datetime.in_time_zone(timezone).strftime('%Y-%m-%d')
      time = datetime.in_time_zone(timezone).strftime('%H:%M')
      friendly_time = datetime.in_time_zone(timezone).strftime('%l:%S %P')
      friendly_datetime = I18n.l(datetime.in_time_zone(timezone), format: :future)

      dates_times[date].push({value: time, friendly_time: friendly_time, friendly_datetime: friendly_datetime }) 
      dates_times[date].uniq!
    end

    dates_times
  end

  def to_s
    "<#{self.class.name}:#{self.object_id}:#{self.size} schedules>"
  end


  def wday
    schedules_intervals.first.datetime.wday
  end
end
