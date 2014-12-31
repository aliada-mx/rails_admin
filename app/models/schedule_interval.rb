class ScheduleInterval
  include ActiveModel::Validations

  validate :schedules_presence
  validate :schedules_continuity

  attr_accessor :schedules
  def initialize(schedules)
    @schedules = schedules
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
end
