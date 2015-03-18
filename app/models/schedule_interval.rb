class ScheduleInterval
  #Represents a contiguous block of schedules 
  include ActiveModel::Validations

  validate :schedules_presence
  validate :schedules_continuity

  attr_accessor :schedules, :aliada_id, :skip_validations
  attr_reader :previous_schedule

  def initialize(schedules, skip_validations: false, aliada_id: nil)
    # Because the users of this class might reuse the passed array we must ensure
    # we get our own duplicate
    @schedules = schedules.dup
    @skip_validations = skip_validations
    @aliada_id = aliada_id
  end

  # For service hours padding purposes
  def free_continuous_hours_in_front(zone)
    start = @schedules.last.datetime
    ending = @schedules.last.datetime + 2.hours

    schedules = Schedule.in_zone(zone).after_datetime(start).in_or_before_datetime(ending).for_aliada_id(@aliada_id)

    if schedules.empty?
      2
    elsif schedules.size == 1
      schedules.first.available? ? 2 : 0
    else
      ( schedules.select{ |s| s.available? } ).size
    end
  end

  def beginning_of_interval
    @schedules.first.datetime
  end

  def ending_of_interval
    @schedules.last.datetime
  end

  def size
    @schedules.size
  end

  def empty?
    size == 0
  end

  def include?(other_schedule)
    @schedules.any? { |schedule| schedule.datetime == other_schedule.datetime }
  end

  # Returns the time difference between the beginning two schedule intervals
  def -(other_schedule_interval)
    return nil unless other_schedule_interval.is_a?(ScheduleInterval)
    beginning_of_interval - other_schedule_interval.beginning_of_interval
  end

  # returns a list of the schedules datetimes
  def schedules_datetimes
    @schedules.map(&:datetime)
  end

  def persist!
    @schedules.map(&:save!)
  end

  def book_schedules(aliada_id: nil, user_id: nil, service_id: nil)
    @schedules.each do |schedule|
      schedule.aliada_id = aliada_id
      schedule.user_id = user_id
      schedule.service_id = service_id
      if aliada_id.present? && user_id.present? && service_id.present?
        schedule.book
      end
      schedule.save!
    end
  end

  def wday
    @schedules.first.datetime.wday
  end

  def self.build_from_range(starting_datetime, ending_datetime, from_existing: false, conditions: {})
    schedules = []

    Time.iterate_in_hour_steps(starting_datetime, ending_datetime).each do |datetime|
      # If we reached the end...
      break if ending_datetime.to_i == datetime

      conditions.merge!({datetime: datetime})

      if from_existing
        schedule = Schedule.find_by(conditions)
        Rails.logger.fatal "Schedule not found with conditions #{conditions}" if schedule.blank?
      else
        schedule = Schedule.new(conditions)
      end

      schedules.push(schedule)
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

  # Following the business rules we determine what would be the first datetime for a service
  def end_of_interval_for_service
    ending_of_interval
  end

  private
    # Validations
    #
    def schedules_presence
      message = 'Make sure you pass a non empty list of schedules'

      errors.add(:presence, message) if @schedules.first.nil? || !@schedules.all?{ |s| s.instance_of?(Schedule) }
    end

    def schedules_continuity
      message = 'Make sure the schedules passed are within on hour each'

      errors.add(:continuity, message) unless ScheduleInterval.continues_datetimes?(schedules_datetimes)
    end
end
