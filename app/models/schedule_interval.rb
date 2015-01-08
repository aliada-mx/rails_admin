class ScheduleInterval
  #Represents a contiguous block of schedules inside a single day

  include ActiveModel::Validations

  validate :schedules_presence
  validate :schedules_valid
  validate :schedules_continuity
  validate :schedules_inside_working_hours

  attr_accessor :schedules, :aliada

  def initialize(schedules, aliada: nil)
    @schedules = schedules
    @aliada = aliada
  end

  # The number of hours it spans to
  def hours_long
    @schedules.last.datetime.hour - @schedules.first.datetime.hour
  end

  # schedules last exactly 1 hour
  def ending_datetime
    @schedules.last.datetime
  end

  def size
    @schedules.size
  end

  def empty?
    size == 0
  end

  def persist_schedules
    @schedules.map(&:save)
  end

  def self.build_from_range(starting_datetime, ending_datetime)
    schedules = []
    (starting_datetime.to_i .. ending_datetime.to_i).step(1.hour) do |date|
      # If we reached the end...
      break if ending_datetime.to_i == date

      schedules.push(Schedule.new(datetime: Time.at(date)))
    end

    new(schedules)
  end

  # True if consecutives datetimes are separated by 1 hour
  def self.continues_datetimes?(datetimes)
    continues = true

    previous_datetime = datetimes.first
    current = nil
    datetimes.each_with_index do |datetime,i|
      next if i == 0

      current = datetime

      if (current - previous_datetime) != 1.hour
        continues = false
        break
      end

      previous_datetime = datetime
    end

    continues
  end

  # From a list of schedules tries to build as many valid schedule intervals as possible
  def self.extract_from_schedules(schedules, schedule_interval_size, aliada: nil)
    schedules.to_a.sort!{ |schedule_a, schedule_b| schedule_a.datetime <=> schedule_b.datetime }

    schedules_intervals = []
    schedules.each_with_index do |schedule,i|
      # Create chunks the size of the schedule_interval_size
      continues_schedules = schedules[i..i+schedule_interval_size-1]

      break if continues_schedules.size < schedule_interval_size

      schedule_interval = ScheduleInterval.new(continues_schedules, aliada: aliada)

      if schedule_interval.valid?
        schedules_intervals.push(schedule_interval) 
      end
    end

    schedules_intervals
  end
  
  def fit_in(other_schedule_interval)
    @schedules.size <= other_schedule_interval.size
  end

  # Based on datetime it returns the schedules in common with the passed schedules
  def common_schedules(available_schedules)
    available_schedules.select { |aliada_schedule| schedules_datetimes.include?(aliada_schedule.datetime) }
  end

  private
    # Validations
    #
    def schedules_presence
      message = 'Make sure you pass a non empty list of schedules'

      errors.add(:base, message) if @schedules.first.nil? || !@schedules.all?{ |s| s.instance_of?(Schedule) }
    end
    
    def schedules_continuity
      message = 'Make sure the schedules passed are within on hour each'

      errors.add(:base, message) unless ScheduleInterval.continues_datetimes?(schedules_datetimes)
    end

    def schedules_inside_working_hours
      message = 'Make sure the schedules passed are within on hour each'
      
      first_hour = @schedules.first.datetime.hour
      last_hour = @schedules.last.datetime.hour
      
      if (first_hour < Setting.beginning_of_aliadas_day) || (last_hour > Setting.end_of_aliadas_day)
        errors.add(:base, message)
      end
    end

    def schedules_valid
      message = 'Make sure all schedules include aliada and a datetime'

      if aliada.present?
        errors.add(:base, message) unless @schedules.all?(&:valid?)
      end
    end
    #
    # End of validations

     
    # returns a list of the schedules datetimes
    def schedules_datetimes
      @schedules.map(&:datetime)
    end
end
