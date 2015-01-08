class Service < ActiveRecord::Base
  attr_accessor :starting_datetime, :week_day

  belongs_to :zone
  belongs_to :address
  belongs_to :user
  belongs_to :service_type
  belongs_to :recurrence
  has_many :schedules

  # validates_presence_of :billable_hours
  validate :service_type_exists

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :user

  after_initialize :set_defaults

  def set_defaults
    self.hours_before_service ||= Setting.hours_before_service
    self.hours_after_service ||= Setting.hours_after_service 
  end

  def service_type_exists
    message = 'El tipo de servicio elegido no existe'

    errors.add(:service_type, message) unless ServiceType.exists? service_type_id
  end

  def service_schedule_possible?
    schedule_checker = ScheduleChecker.new(self)
    schedule_checker.possible?
  end

  def total_hours
    hours_before_service + billable_hours + hours_after_service
  end
end
