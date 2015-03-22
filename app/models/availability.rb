# Represents a series of unique schedule intervals available by a single or many aliadas
class Availability
  extend Forwardable

  def_delegators :@store, :[], :delete, :has_key?, :empty?, :present?, :each, :first, :second, :blank?
  def_delegator :@store, :keys, :ids
  def_delegator :@store, :has_key?, :has_aliada?
  attr_accessor :store 
  attr_accessor :iterable_store 
  attr_accessor :previous_service_schedules
  attr_reader :aliada

  def initialize(aliada: nil)
    # A hash with an array as default value for new keys
    @store = {}
    @aliada = aliada
  end

  def add(wday_hour, new_interval, aliada_id)
    if @store[aliada_id].nil?
      @store[aliada_id] = {}
    end

    if @store[aliada_id][wday_hour].nil? 
      @store[aliada_id][wday_hour] = {}
    end

    if @store[aliada_id][wday_hour][new_interval.key].nil?
      @store[aliada_id][wday_hour][new_interval.key] = {}
    end

    @store[aliada_id][wday_hour][new_interval.key] = new_interval
  end

  def schedules_intervals
    @store.collect do |aliada_id, wday_hour_intervals|
      if wday_hour_intervals
        wday_hour_intervals.collect do |wday_hour, intervals_hash|
          intervals_hash.collect do |interval_key, interval|
            interval
          end
        end
      end
    end.flatten
  end

  def schedules
    schedules_intervals.map(&:schedules).flatten
  end

  def previous_interval(aliada_id, wday_hour, current_interval)
    aliadas_wday_hour_intervals = @store[aliada_id]
    return nil if aliadas_wday_hour_intervals.nil?

    intervals_hash = aliadas_wday_hour_intervals[wday_hour]
    return nil if intervals_hash.nil?

    interval_key = current_interval.key
    return nil if intervals_hash[interval_key].nil?

    intervals_hash.values.last
  end

  def size
    @store.size
  end

  def delete_if(&tester)
    @store.each do |aliada_id, aliada_intervals_hash|
      value = tester.call(aliada_id, aliada_intervals_hash)

      @store.delete(aliada_id) if value
    end  
  end

  def for_aliada(aliada)
    aliada_availability = Availability.new(aliada: aliada)
    aliada_availability.store = @store[aliada.id].present? ? { aliada.id => @store[aliada.id] } : {}
    aliada_availability.previous_service_schedules = previous_service_schedules
    aliada_availability
  end

  def book(service)
    if schedules_intervals.present? && aliada.present?
      last_interval = nil
      schedules_intervals.each do |schedule_interval|
        schedule_interval.book_schedules(aliada_id: aliada.id,
                                         user_id: service.user_id,
                                         service_id: service.id)
        last_interval = schedule_interval
      end
      service.assign(aliada)
    else
      service.mark_as_missing
    end
    service.hours_after_service = last_interval.padding_count
    service.ensure_updated_recurrence!

    service.save!

    self
  end

  def enable_unused_schedules
    return if previous_service_schedules.blank?

    unused = previous_service_schedules - self.schedules

    unused.each do |schedule|
      schedule.enable_booked
    end
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
      datetime = schedule_interval.beginning_of_interval

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
    schedules.first.datetime.wday
  end
end
