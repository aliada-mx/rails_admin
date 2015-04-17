# -*- encoding : utf-8 -*-
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

    # Only save the largest one
    existing_interval = @store[aliada_id][wday_hour][new_interval.key]
    if existing_interval.present? 
      if existing_interval.size < new_interval.size
        @store[aliada_id][wday_hour][new_interval.key] = new_interval
      end
    else
      @store[aliada_id][wday_hour][new_interval.key] = new_interval
    end
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
    service_shared_attributes = service.shared_attributes

    schedules_intervals.each_with_index do |schedule_interval, i|
      # The first service is already created at this point
      service = Service.new(service_shared_attributes) if i != 0

      assign_interval_attributes_to_service(service, schedule_interval, service.recurrence_id)
    end

    self
  end

  def assign_interval_attributes_to_service(service, schedule_interval, recurrence_id)
    service.datetime = schedule_interval.beginning_of_interval 

    service.aliada_id = schedule_interval.aliada_id

    service.hours_after_service = schedule_interval.padding_count

    service.assign(aliada)

    service.save!

    schedule_interval.book_schedules(aliada_id: aliada.id,
                                     user_id: service.user_id,
                                     service_id: service.id,
                                     recurrence_id: recurrence_id) # the recurrence_id can be nil for one-time services
  end

  def rebook_recurrence(recurrence)
    shared_attributes = recurrence.attributes_shared_with_service
    shared_attributes.merge!({ 'service_type' => ServiceType.recurrent,
                               'recurrence_id' => recurrence.id })

    schedules_intervals.each_with_index do |schedule_interval, i|
      service = Service.new(shared_attributes)

      assign_interval_attributes_to_service(service, schedule_interval, recurrence.id)
    end

    self
  end

  def enable_unused_schedules
    return if previous_service_schedules.blank?

    unused = previous_service_schedules - self.schedules

    unused.each do |schedule|
      schedule.enable_booked
    end
  end

  # We asume the same padding
  def padding_count
    schedules_intervals.first.padding_count
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
      datetime = schedule_interval.beginning_of_interval.in_time_zone(timezone)
      if datetime.dst?
        datetime -= 1.hour
      end

      date = datetime.strftime('%Y-%m-%d')
      time = datetime.strftime('%H:%M')
      friendly_time = datetime.strftime('%l:%S %P')
      friendly_datetime = I18n.l(datetime, format: :future)

      dates_times[date].push({value: time, friendly_time: friendly_time, friendly_datetime: friendly_datetime }) 
      dates_times[date].uniq!
      dates_times[date].sort_by!{ |date_time| date_time[:value] }
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
