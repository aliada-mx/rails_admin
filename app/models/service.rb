class Service < ActiveRecord::Base
  include Presenters::ServicePresenter
  STATUSES = [
    ['Creado','created'],
    ['Aliada asignada', 'aliada_assigned'],
    ['Sin aliada', 'aliada_missing'],
    ['En progreso..', 'in-progress'],
    ['Terminado', 'finished'],
    ['Pagado', 'paid'],
    ['Cancelado', 'canceled'],
  ]
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[1] } }
  # accessors for forms
  attr_accessor :postal_code, :time, :date, :payment_method_id, :conekta_temporary_token

  belongs_to :address
  belongs_to :user, inverse_of: :services, foreign_key: :user_id
  belongs_to :aliada, inverse_of: :services, foreign_key: :aliada_id
  belongs_to :payment_method
  belongs_to :recurrence
  belongs_to :service_type
  belongs_to :zone
  has_many :extra_services
  has_many :extras, through: :extra_services
  has_many :schedules
  has_many :tickets, as: :relevant_object

  # Scopes
  scope :in_the_past, -> { where("datetime < ?", Time.zone.now) }
  scope :in_the_future, -> { where("datetime >= ?", Time.zone.now) }

  scope :on_day, -> (datetime) { where('datetime >= ?', datetime.beginning_of_day).where('datetime <= ?', datetime.end_of_day) } 
  # Validations
  validate :datetime_is_hour_o_clock
  validate :datetime_within_working_hours
  validate :service_type_exists
  validates_presence_of :address, :user, :estimated_hours, :datetime, :service_type

  # Callbacks
  after_initialize :set_defaults
  after_create :ensure_zone!

  # TODO: Fix validations, it is only working with :created
  # State machine
  state_machine :status, :initial => 'created' do
    transition 'created' => 'aliada_assigned', :on => :assign
    transition 'created' => 'aliada_missing', :on => :mark_as_missing
    transition 'created' => 'paid', :on => :pay
    transition ['created', 'aliada_assigned', 'in-progress'] => 'finished', :on => :finish
    transition ['created', 'aliada_assigned' ] => 'cancelled', :on => :cancel

    after_transition :on => :mark_as_missing, :do => :create_aliada_missing_ticket

    after_transition on: :assign do |service, transition|
      aliada = transition.args.first

      service.aliada = aliada
      service.save!

      if service.recurrent?
        recurrence = service.recurrence
        recurrence.aliada = aliada if service.recurrent?
        recurrence.save!
      end
    end
  end

  # Ask service_type to answer recurrent? method for us
  delegate :recurrent?, to: :service_type
  delegate :one_timer?, to: :service_type

  # Callbacks
  def set_defaults
    self.status ||= 'created' if self.respond_to? :status
    self.hours_before_service ||= get_hours_before_service if self.respond_to? :hours_before_service
    self.hours_after_service ||= get_hours_after_service if self.respond_to? :hours_after_service
  end

  def get_hours_before_service
    Setting.beginning_of_aliadas_day == datetime.try(:hour) ? 0 : Setting.hours_before_service
  end

  def get_hours_after_service
    Setting.end_of_aliadas_day == datetime.try(:hour) ? 0 : Setting.hours_after_service
  end

  def combine_date_time
    Chronic.time_class = Time.zone
    self.datetime = Chronic.parse "#{self.date} #{self.time}"
  end

  def ensure_recurrence!
    return unless recurrent?

    if self.recurrence.blank?
      self.recurrence = Recurrence.create!(user_id: user_id,
                                           periodicity: service_type.periodicity,
                                           total_hours: total_hours,
                                           hour: beginning_datetime.hour,
                                           weekday: datetime.weekday)
      self.save!
    end
  end

  def ensure_zone!
    return if zone_id.present?
    return unless address_id.present? 

    self.zone_id = address.postal_code.zone.id
    self.save!
  end

  def self.create_aliada_missing_ticket
    Ticket.create_warning message: "No se encontró una aliada para el servicio", 
                          action_needed: "Asigna una aliada al servicio",
                          relevant_object: @service

  end

  def total_hours
    hours_before_service + estimated_hours + hours_after_service
  end

  # Starting now how many days we'll provide service to the end of
  # the recurrence
  def days_count_to_end_of_recurrency
    current_datetime = Time.zone.now
    ending_datetime = current_datetime + Setting.time_horizon_days.days
    
    periodicity = recurrence.periodicity.days
    count = 0

    while current_datetime < ending_datetime
      current_datetime += periodicity
      count +=1
    end
    count
  end

  def ending_datetime
    beginning_datetime + total_hours.hours
  end

  # The datetime that effectively starts consuming an aliada's real time
  def beginning_datetime
    datetime - hours_before_service.hours
  end

  def book_aliada! 
    aliadas_availability = ScheduleChecker.find_aliadas_availability(self)

    aliada_availability = AliadaChooser.find_aliada_availability(aliadas_availability, self)

    aliada = aliada_availability[:aliada]
    schedules_intervals = aliada_availability[:availability]

    if schedules_intervals.present? && aliada.present?
      schedules_intervals.each do |schedule_interval|
        schedule_interval.book_schedules!(aliada_id: aliada.id, user_id: user_id, service_id: self.id)
      end
      assign!(aliada)
    else
      mark_as_missing!
    end
    save!
  end

  def to_schedule_interval
    ScheduleInterval.build_from_range(beginning_datetime, ending_datetime)
  end

  def self.create_initial!(service_params)
    address = Address.create!(service_params[:address])
    user = User.create!(service_params[:user])
    service = Service.new(service_params.except!(:user, :address))

    service.address = address
    service.user = user
    service.combine_date_time
    service.ensure_recurrence!

    service.save!

    user.create_first_payment_provider!(service_params[:payment_method_id])
    user.ensure_first_payment!(service_params)

    service.book_aliada!
    service
  end

  # Validations
  def service_type_exists
    message = 'El tipo de servicio elegido no existe'

    errors.add(:service_type, message) unless ServiceType.exists? service_type_id
  end

  def datetime_is_hour_o_clock
    message = 'Los servicios solo pueden crearse en horas en punto'

    errors.add(:datetime, message) if datetime.min != 0 || datetime.sec != 0
  end

  def datetime_within_working_hours
    message = 'No podemos registrar un servicio que empieza o termina fuera del horario de trabajo'

    first_hour = datetime.hour
    last_hour = ending_datetime.hour

    working_range = [*Setting.beginning_of_aliadas_day..Setting.end_of_aliadas_day]

    unless working_range.include?(first_hour) && working_range.include?(last_hour)
      errors.add(:datetime, message)
    end
  end

  rails_admin do
    label_plural 'servicios'
    navigation_label 'Operación'
    navigation_icon 'icon-home'
    list do
      sort_by :datetime

      field :user_link do
        virtual?
      end
      field :datetime do
        sort_reverse false
      end
      field :status
    end

  end
end
