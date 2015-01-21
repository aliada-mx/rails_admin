class Service < ActiveRecord::Base
  STATUSES = [
    ['pending','Pendiente por realizarse'],
    ['in-progress','En progreso..'],
    ['finished','Terminado'],
    ['payed','Pagado'],
    ['canceled','Cancelado'],
  ]
  attr_accessor :postal_code

  belongs_to :zone
  belongs_to :address
  belongs_to :user
  belongs_to :service_type
  belongs_to :recurrence
  belongs_to :payment_method
  has_many :schedules
  has_many :extra_services
  has_many :extras, through: :extra_services

  # validates_presence_of [:billable_hours, :date, :time]
  # validate :time_is_hour_o_clock
  validate :service_type_exists

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :user

  after_initialize :set_defaults
  before_save :create_update_recurrency

  state_machine :status, :initial => 'pending' do
  end

  def set_defaults
    self.status ||= 'pending' if self.respond_to? :status
    self.hours_before_service ||= Setting.hours_before_service if self.respond_to? :hours_before_service 
    self.hours_after_service ||= Setting.hours_after_service if self.respond_to? :hours_after_service 
  end

  def total_hours
    hours_before_service + billable_hours + hours_after_service
  end

  def create_user

  end

  # def create_schedules(aliada)
  #   datetime = Datetime.new(date.year, date.month, date.day, time.hour, time.min, time.sec)

  #   if service_type.recurrent?
  #     return recurrency.to_schedule_intervals
  #   else
  #     return Schedule.build_one_timer(datetime, total_hours, aliada)
  #   end
  # end

  def create_update_recurrency

  end

  # Validations
  def service_type_exists
    message = 'El tipo de servicio elegido no existe'

    errors.add(:service_type, message) unless ServiceType.exists? service_type_id
  end

  # def time_is_hour_o_clock
  #   message = 'Los servicios solo pueden crearse en horas cerradas'

  #   errors.add(:time, message) if time.min != 0 || time.sec != 0
  # end
end
