# Represents a series of unique schedule intervals available per aliada
class Availability
  attr_accessor :store 
  extend Forwardable

  def_delegators :@store, :delete_if, :[], :empty?, :delete, :present?, :each, :has_key?
  def_delegator :@store, :keys, :ids
  def_delegator :@store, :has_key?, :has_aliada?

  def initialize
    # A hash with an array as default value for new keys
    @store = Hash.new{ |h,k| h[k] = [] }
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
    OpenStruct.new({aliada: aliada, schedules_intervals: schedules_intervals.select{ |s| s.aliada_id == aliada.id } })
  end

  def schedules_intervals
    @store.values.flatten
  end

  def beginning
    schedules_intervals.first.beginning_of_interval
  end

  # format expected by jquery.calendario
  def for_calendario(timezone)
    # A hash with an array as default value for new keys
    dates_times = Hash.new{ |h,k| h[k] = [] }

    schedules_intervals.map do |schedule_interval|
      datetime = schedule_interval.beginning_of_interval

      date = datetime.in_time_zone(timezone).strftime('%Y-%m-%d')
      time = datetime.in_time_zone(timezone).strftime('%H:%M')
      friendly_time = datetime.in_time_zone(timezone).strftime('%l:%S %P')
      friendly_date = I18n.l(datetime.in_time_zone(timezone), format: :future)

      dates_times[date].push({value: time, friendly_time: friendly_time, friendly_datetime: friendly_date }) 
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
