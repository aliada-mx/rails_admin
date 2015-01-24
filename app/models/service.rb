class Service < ActiveRecord::Base
  STATUSES = [
    ['created','Creado'],
    ['aliada_assigned','Aliada asignada'],
    ['aliada_missing','Sin aliada'],
    ['in-progress','En progreso..'],
    ['finished','Terminado'],
    ['payed','Pagado'],
    ['canceled','Cancelado'],
  ]

  # Associations
  attr_accessor :postal_code, :time, :date
  belongs_to :address
  belongs_to :aliada, inverse_of: :services
  belongs_to :payment_method
  belongs_to :recurrence
  belongs_to :service_type
  belongs_to :ticket, as: :relevant_object
  belongs_to :user, inverse_of: :services
  belongs_to :zone
  has_many :extra_services
  has_many :extras, through: :extra_services
  has_many :schedules

  # Nested attributes
  accepts_nested_attributes_for :user
  accepts_nested_attributes_for :address

  # Validations
  validates_presence_of [:billable_hours, :datetime]
  validate :datetime_is_hour_o_clock
  validate :service_type_exists
  validates_presence_of [:address, :user]

  # Callbacks
  after_initialize :set_defaults
  after_initialize :combine_date_time
  before_save :create_update_recurrency

  # State machine
  state_machine :status, :initial => 'pending' do
  end

  # Callbacks
  def set_defaults
    self.status ||= 'pending' if self.respond_to? :status
    self.hours_before_service ||= Setting.hours_before_service if self.respond_to? :hours_before_service
    self.hours_after_service ||= Setting.hours_after_service if self.respond_to? :hours_after_service
  end

  def combine_date_time
    if self.time.present? and self.date.present?
      date = Time.zone.parse(self.date)
      time = Time.zone.parse(self.time)

      self.datetime = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec)
    end
  end

  def ensure_recurrence
    return unless service_type.recurrent?

    unless recurrence.present?
      Recurrence.create!(user_id: user_id,
                         aliada_id: aliada_id,
                         periodicity: service_type.periodicity,
                         hour: datetime.hour,
                         weekday: datetime.weekday)
    end
  end

  def total_hours
    hours_before_service + billable_hours + hours_after_service
  end

  def book_with!(aliada_availability)
    self.aliada_id = aliada_availability.keys.first
    self.save!

    available_schedules = aliada_availability.keys.second

    available_schedules.each do |schedule_interval|
      schedule_interval.book_schedules!(self.aliada_id, self.user_id)
    end
  end

  def new_recurrent
    recurrence.to_schedule_intervals(total_hours, create: false, conditions: {user_id: user_id, aliada_id: aliada_id})
  end

  def new_one_timer
    schedule_interval = ScheduleInterval.get_from_range(datetime, datetime + total_hours.hours)
  end

  # Validations
  def service_type_exists
    message = 'El tipo de servicio elegido no existe'

    errors.add(:service_type, message) unless ServiceType.exists? service_type_id
  end

  def datetime_is_hour_o_clock
    message = 'Los servicios solo pueden crearse en horas cerradas'

    errors.add(:datetime, message) if datetime.min != 0 || datetime.sec != 0
  end
end
