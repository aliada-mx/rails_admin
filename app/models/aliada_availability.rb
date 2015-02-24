# Represents a series of shcedules intervals available 
# for booking per aliada for a certain service
class AliadaAvailability
  attr_accessor :store 
  attr_accessor :banned_aliadas_ids

  def initialize(service)
    @service = service
    # A hash with an array as default value for new keys
    @store = Hash.new{ |h,k| h[k] = [] }

    @recurrency_days = @service.recurrence.periodicity.days if @service.recurrent?
  end

  def add(aliada_id, continuous_schedules)
    @aliada_id = aliada_id

    continuous_schedules.each do |continuous_schedule|
      # Ensure is the right type
      if continuous_schedule.class == ScheduleInterval
        interval = continuous_schedule
      else
        interval = ScheduleInterval.new(continuous_schedule)
      end

      if allow_to_add?(interval)
        @store[@aliada_id].push(interval)
      else
        # If the schedules intervals continuity is broken the whole chain is
        remove_aliada_availability! if @service.recurrent?
      end
    end
  end

  def [](key)
    @store[key]
  end

  def size
    @store.values.size
  end

  def empty?
    @store.empty?
  end

  def delete(aliada_id)
    @store.delete(aliada_id)
  end

  def ids
    @store.keys
  end

  def has_aliada?(aliada)
    @store.has_key?(aliada.id)
  end

  def schedules
    @store.values.flatten.map(&:schedules).flatten
  end

  def for_aliada(aliada)
    {aliada: aliada, availability: @store[aliada.try(:id)] }
  end
   
  def continuous_schedule_intervals?(previous_interval, current_interval, aliada_id)
    (current_interval - previous_interval) == @recurrency_days
  end

  def allow_to_add?(continuous_schedule)
    if @service.one_timer?
      allow_to_add_one_timer?
    elsif @service.recurrent?
      allow_to_add_recurrent?(continuous_schedule)
    end
  end

  private

    def allow_to_add_recurrent?(current_interval)
      previous_interval = @store[@aliada_id].last

      # The first time there's no continuity possible so asume its valid
      return true if previous_interval.blank?

      continuous_schedule_intervals?(previous_interval, current_interval, @aliada_id)
    end

    def allow_to_add_one_timer?
      @store[@aliada_id].size == 0
    end

    def remove_aliada_availability!
      @store.delete(@aliada_id)
    end

end
