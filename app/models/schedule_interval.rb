class ScheduleInterval
  #Represents a contiguous block of schedules inside a single day

  include ActiveModel::Validations

  validate :all_validations

  attr_accessor :schedules, :aliada, :skip_validations

  def initialize(schedules, aliada_id: nil, skip_validations: false)
    # Because the users of this class might reuse the passed array we must ensure
    # we get our own duplicate
    @schedules = schedules.dup
    @aliada_id = aliada_id
    @skip_validations = skip_validations
  end

  def beginning_of_interval
    @schedules.first.datetime
  end

  def ending_of_interval
    @schedules.last.datetime
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

  def persist!
    @schedules.map(&:save)
    self
  end

  def self.build_from_range(starting_datetime, ending_datetime, aliada: nil, use_persisted_schedules: false)
    schedules = []
    (starting_datetime.to_i .. ending_datetime.to_i).step(1.hour) do |date|
      # If we reached the end...
      break if ending_datetime.to_i == date

      datetime = Time.at(date)

      if use_persisted_schedules
        schedule = Schedule.find_by_datetime_and_aliada_id(datetime, aliada.id)
      else
        schedule = Schedule.new(datetime: datetime, aliada: aliada)
      end
      schedules.push(schedule)
    end

    if aliada
      new(schedules, aliada.id)
    else
      new(schedules)
    end
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

  def fit_in(other_schedule_interval)
    @schedules.size <= other_schedule_interval.size
  end

  # Based on datetime it returns the schedules in common with the passed schedules
  def common_schedules(available_schedules)
    available_schedules.select { |aliada_schedule| schedules_datetimes.include?(aliada_schedule.datetime) }
  end

  # returns a list of the schedules datetimes
  def schedules_datetimes
    @schedules.map(&:datetime)
  end

  private
    # Validations
    #
    def all_validations
      unless skip_validations
        schedules_presence
        schedules_continuity
        schedules_inside_working_hours
      end
    end

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
    # End of validations
end
