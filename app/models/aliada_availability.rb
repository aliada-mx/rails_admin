# Represents a series of schedule intervals available per aliada
class AliadaAvailability
  attr_accessor :store 
  extend Forwardable

  def_delegators :@store, :delete_if, :[], :empty?, :delete, :present?, :each
  def_delegator :@store, :keys, :ids
  def_delegator :@store, :has_key?, :has_aliada?

  def initialize(recurrent: false, periodicity: nil)
    @recurrent = recurrent

    # A hash with an array as default value for new keys
    @store = Hash.new{ |h,k| h[k] = [] }

    @recurrency_seconds = periodicity
  end

  def add(aliada_id, continuous_schedules)
    @aliada_id = aliada_id

    continuous_schedules.each do |continuous_schedule|
      # Ensure is the right type
      if continuous_schedule.class == ScheduleInterval
        new_interval = continuous_schedule
      else
        new_interval = ScheduleInterval.new(continuous_schedule)
      end

      if allow_to_add?(new_interval)
        @store[@aliada_id].push(new_interval)
      else
        # If the schedules intervals continuity is broken the whole chain is
        remove_aliada_availability! if @recurrent
      end
    end
  end

  def size
    @store.values.size
  end

  def schedules
    @store.values.flatten.map(&:schedules).flatten
  end

  def for_aliada(aliada)
    {aliada: aliada, availability: @store[aliada.try(:id)] }
  end

  def continuous_schedule_intervals?(previous_interval, current_interval, aliada_id)
    (current_interval - previous_interval) == @recurrency_seconds
  end
   
  private
    def allow_to_add_recurrent?(current_interval)
      previous_interval = @store[@aliada_id].last

      # The first time there's no continuity possible so asume its valid
      return true if previous_interval.blank?

      continuous_schedule_intervals?(previous_interval, current_interval, @aliada_id)
    end

    def allow_to_add_one_timer?
      @store[@aliada_id].size.zero?
    end

    def remove_aliada_availability!
      @store.delete(@aliada_id)
    end

    def allow_to_add?(new_interval)
      if @recurrent
        allow_to_add_recurrent?(new_interval)
      else
        allow_to_add_one_timer?
      end
    end
end
