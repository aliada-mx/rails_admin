class Service < ActiveRecord::Base
  include Presenters::ServicePresenter
  include AliadaSupport::DatetimeSupport

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
  attr_accessor :postal_code, :time, :date, :payment_method_id, :conekta_temporary_token, :timezone

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
  has_one :score

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
  delegate :periodicity, to: :service_type

  def timezone
    'Mexico City'
  end

  def timezone_offset_seconds
    zone = ActiveSupport::TimeZone[timezone]
    # we dont use the zone offset because it doesnt take DST into consideration
    time = Time.now
    time.in_time_zone(zone).utc_offset
  end

  def timezone_offset_hours
    timezone_offset_seconds / 3600
  end

  def cost
    65
  end

  # Callbacks
  def set_defaults
    self.status ||= 'created' if self.respond_to? :status
    set_hours_before_after_service
  end

  def set_hours_before_after_service
    self.hours_before_service = Setting.beginning_of_aliadas_day == datetime.try(:hour) ? 0 : Setting.hours_before_service
    self.hours_after_service = Setting.end_of_aliadas_day == datetime.try(:hour) ? 0 : Setting.hours_after_service
  end

  def combine_date_time
    self.datetime = ActiveSupport::TimeZone[timezone].parse("#{self.date} #{self.time}")
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

  def create_aliada_missing_ticket
    Ticket.create_warning message: "No se encontró una aliada para el servicio", 
                          action_needed: "Asigna una aliada al servicio",
                          relevant_object: self
  end

  def total_hours
    hours_before_service + estimated_hours + hours_after_service
  end

  # Starting now how many days we'll provide service to the end of
  # the recurrence
  def days_count_to_end_of_recurrency
    wdays_until_horizon(Time.zone.now.wday, starting_from: starting_datetime_to_book_services(timezone))
  end

  def ending_datetime
    beginning_datetime + total_hours.hours
  end

  # The datetime that effectively starts consuming an aliada's real time
  def beginning_datetime
    datetime - hours_before_service.hours
  end

  def book_aliada!(aliada_id: nil)
    available_after = starting_datetime_to_book_services(timezone)

    aliadas_availability = AvailabilityForService.find_aliadas_availability(self, available_after, aliada_id: aliada_id)

    aliada_availability = AliadaChooser.find_aliada_availability(aliadas_availability, self)

    aliada = aliada_availability.aliada
    schedules_intervals = aliada_availability.schedules_intervals

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

  def self.create_new!(service_params, user)
    ActiveRecord::Base.transaction do
      address = user.default_address
      service = Service.new(service_params.except!(:user, :address))

      service.address = address
      service.user = user
      service.combine_date_time
      service.set_hours_before_after_service
      service.ensure_recurrence!

      service.save!

      user.send_confirmation_email(service)

      service.book_aliada!
      return service
    end
  end

  def self.create_initial!(service_params)
    ActiveRecord::Base.transaction do
      address = Address.create!(service_params[:address])
      user = User.create!(service_params[:user])
      service = Service.new(service_params.except!(:user, :address))

      service.address = address
      service.user = user
      service.combine_date_time
      service.set_hours_before_after_service
      service.ensure_recurrence!

      service.save!

      user.addresses << address
      user.create_first_payment_provider!(service_params[:payment_method_id])
      user.ensure_first_payment!(service_params)
      user.send_welcome_email

      service.book_aliada!
      return service
    end
  end

  def one_time_schedule_intervals
    ScheduleInterval.build_from_range(datetime, ending_datetime)
  end

  def recurrent_schedule_intervals
    recurrence.to_schedule_intervals(total_hours.hours)
  end

  def to_schedule_intervals
    if service_type.recurrent?
      recurrent_schedule_intervals
    else
      [one_time_schedule_intervals]
    end
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

    beginning_of_aliadas_day = Time.now.utc.change(hour: Setting.beginning_of_aliadas_day)
    end_of_aliadas_day = Setting.end_of_aliadas_day
    datetime_hour = datetime.hour

    found = false
    while true
      break if beginning_of_aliadas_day.hour == end_of_aliadas_day

      if datetime_hour == beginning_of_aliadas_day.hour 
        found = true
        break
      end

      beginning_of_aliadas_day += 1.hour
    end 

    errors.add(:datetime, message) unless found
  end

  rails_admin do
    label_plural 'servicios'
    navigation_label 'Operación'
    navigation_icon 'icon-home'
    configure :schedules do
      visible false
    end

    list do
      sort_by :datetime

      field :user_link do
        virtual?
      end
      field :datetime do
        sort_reverse false
        pretty_value do
          
          I18n.l(value , format: :friendly).titleize
        end
      end
      field :status
    end

  end
end
