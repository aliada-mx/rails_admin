class ScheduleInterval
  #Represents a contiguous block of schedules inside a single day

  include ActiveModel::Validations

  validate :schedules_presence
  validate :schedules_continuity
  validate :schedules_inside_working_hours

  attr_accessor :schedules, :aliada, :skip_validations

  def initialize(schedules, skip_validations: false)
    # Because the users of this class might reuse the passed array we must ensure
    # we get our own duplicate
    @schedules = schedules.dup
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

  # returns a list of the schedules datetimes
  def schedules_datetimes
    @schedules.map(&:datetime)
  end

  def book_schedules!
    @schedules.map(&:book!)
  end

  def asign_to_user(user_id)
    @schedules.map{ |schedule| schedule.user_id = user_id }
    self
  end

  def asign_to_aliada(aliada_id)
    @schedules.map{ |schedule| schedule.aliada_id = aliada_id }
    self
  end

  def self.filter_broken_recurrency(aliadas_availability)
    aliada_availability.each do |aliada_id, available_schedules_intervals|

      previous_schedule_interval = available_schedules_intervals.first
      available_schedules_intervals.each do |schedule_interval|
        if (schedule_interval.beginning_of_interval - schedule_interval.beginning_of_interval) != 1.day
          aliada_availability.delete(aliada_id)
          break
        end
      end
    end

    aliada_availability
  end

  def self.build_from_range(starting_datetime, ending_datetime, schedule_proc, conditions: conditions)
    schedules = []
    (starting_datetime.to_i .. ending_datetime.to_i).step(1.hour) do |date|
      # If we reached the end...
      break if ending_datetime.to_i == date

      datetime = Time.zone.at(date)
      puts "puts #{datetime}"
      conditions.merge!({datetime: datetime})

      schedule = schedule_proc.call(conditions)

      binding.pry if schedule.blank?
      raise "Schedule not found with conditions #{conditions}" if schedule.blank?

      schedules.push(schedule)
    end

    new(schedules)
  end

  # Get the schedules from the database
  def self.get_from_range(starting_datetime, ending_datetime, conditions: {})
    Rails.logger.info "Calling get from range"
    ScheduleInterval.build_from_range(starting_datetime, ending_datetime, lambda { |conditions| Schedule.find_by(conditions) }, conditions: conditions)
  end

  # Create
  def self.create_from_range(starting_datetime, ending_datetime, conditions: {})
    Rails.logger.info "Calling create from range"
    ScheduleInterval.build_from_range(starting_datetime, ending_datetime, lambda { |conditions| Schedule.new(conditions) }, conditions: conditions)
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
      message = 'Make sure the schedules passed inside the working hours'

      first_hour = @schedules.first.datetime.hour
      last_hour = @schedules.last.datetime.hour

      if (first_hour < Setting.beginning_of_aliadas_day) || (last_hour > Setting.end_of_aliadas_day)
        errors.add(:base, message)
      end
    end
    # End of validations
end
