class ScheduleInterval
#Represents a contiguous block of schedules inside a single day

  include ActiveModel::Validations

  validate :schedules_presence
  validate :schedules_valid
  validate :schedules_continuity
  validate :schedules_inside_working_hours

  attr_accessor :schedules
  def initialize(schedules)
    @schedules = schedules
  end

  def self.create_from_range(start_date, end_date, aliada)
    schedules = []
    (start_date.to_i .. end_date.to_i).step(1.hour) do |date|
      schedules.push(Schedule.new(datetime: Time.at(date), aliada: aliada, ))
    end

    new(schedules)
  end

  def schedules_presence
    message = 'Make sure you pass a non empty list of schedules'

    errors.add(:base, message) if @schedules.first.nil? || !@schedules.all?{ |s| s.instance_of?(Schedule) }
  end
  

  
  def schedules_continuity
    message = 'Make sure the schedules passed are within on hour each'

    previous_schedule = @schedules.first
    current = nil
    @schedules.each_with_index do |schedule,i|
      next if i == 0

      current = schedule

      if (current.datetime - previous_schedule.datetime) != 1.hour
        errors.add(:base, message) 
        break
      end

      previous_schedule = schedule
    end
  end

  def schedules_inside_working_hours
    message = 'Make sure the schedules passed are within on hour each'
    
    first = @schedules.first
    last = @schedules.last
    
    if (first.datetime.hour < Setting.beginning_of_aliadas_day) || (last.datetime.hour > Setting.end_of_aliadas_day)
      errors.add(:base, message)
    end
  end

  def schedules_valid
    message = 'Make sure all schedules include aliada and a datetime'

    errors.add(:base, message) unless @schedules.all?(&:valid?)
  end

  def save_schedules
    @schedules.map(&:save)
  end
end
