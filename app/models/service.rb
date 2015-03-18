# -*- coding: utf-8 -*-
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
  attr_accessor :postal_code, :payment_method_id, :conekta_temporary_token, :timezone

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
  scope :not_canceled, -> { where('services.status != ?', 'canceled') }

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
    transition ['created', 'aliada_assigned' ] => 'canceled', :on => :cancel

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

    before_transition on: :cancel do |service, transition|
      service.cancel_schedules!
    end
  end

  # Ask service_type to answer recurrent? method for us
  delegate :recurrent?, to: :service_type
  delegate :one_timer?, to: :service_type
  delegate :periodicity, to: :service_type
  delegate :weekday_in_spanish, to: :recurrence

  def timezone
    'Mexico City'
  end

  def self.timezone
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

  def create_service_charge_failed_ticket(user, amount,error)
    Ticket.create_error(relevant_object_id: self.id,
                        relevant_object_type: 'Service',
                        message: "No se pudo realizar cargo de #{amount} a la tarjeta de #{user.first_name} #{user.last_name}. #{error.message_to_purchaser}")
  end
  
  def cost
    (estimated_hours_without_extras * service_type.price_per_hour).ceil
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

  def self.parse_date_time(params)
    ActiveSupport::TimeZone[self.timezone].parse("#{params[:date]} #{params[:time]}")
  end

  def ensure_updated_recurrence!
    return unless recurrent?

    recurrence_attributes = {user_id: user_id,
                             periodicity: service_type.periodicity,
                             total_hours: total_hours,
                             hour: beginning_datetime.hour,
                             weekday: datetime.weekday }

    if self.recurrence.blank?
      self.recurrence = Recurrence.create!(recurrence_attributes)
    else
      self.recurrence.update_attributes!(recurrence_attributes)
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

  # Starting the next recurrence day how many days we'll provide service until the horizon
  def days_count_to_end_of_recurrency(starting_after_datetime)
    wdays_until_horizon(datetime.wday, starting_from: next_day_of_recurrence(starting_after_datetime))
  end

  def ending_datetime
    beginning_datetime + total_hours.hours
  end

  # The datetime that effectively starts consuming an aliada's real time
  def beginning_datetime
    datetime - hours_before_service.hours
  end

  def book_aliada(aliada_id: nil)
    available_after = starting_datetime_to_book_services

    aliadas_availability = AvailabilityForService.find_aliadas_availability(self, available_after, aliada_id: aliada_id)

    raise AliadaExceptions::AvailabilityNotFound if aliadas_availability.empty?

    aliada_availability = AliadaChooser.choose_availability(aliadas_availability, self)

    aliada_availability.book(self)
  end
  
  #calculates the price to be charged for a service
  def amount_to_bill
    
    hours = self.aliada_reported_end_time.hour - self.aliada_reported_begin_time.hour
    minutes = self.aliada_reported_end_time.min - self.aliada_reported_begin_time.min 
    amount = (hours*(self.service_type.price_per_hour))+(minutes * ((self.service_type.price_per_hour)/60.0))
    
   
    if amount > 0 && (self.aliada_reported_end_time.to_date === self.aliada_reported_begin_time.to_date)
      return amount
    else
      return 0
    end
  end

  def cancel_schedules!
    self.schedules.in_the_future.map(&:enable_booked!)
  end

  def self.create_new!(service_params, user)
    ActiveRecord::Base.transaction do
      service_params[:datetime] = Service.parse_date_time(service_params)

      address = user.default_address
      service = Service.new(service_params.except!(:user, :address))

      service.address = address
      service.user = user
      service.set_hours_before_after_service
      service.ensure_updated_recurrence!

      service.save!

      service.book_aliada

      user.send_confirmation_email(service)
      return service
    end
  end

  def self.create_initial!(service_params)
    ActiveRecord::Base.transaction do
      service_params[:datetime] = Service.parse_date_time(service_params)

      address = Address.create!(service_params[:address])
      user = User.create!(service_params[:user])
      service = Service.new(service_params.except!(:user, :address))

      service.address = address
      service.user = user
      service.set_hours_before_after_service
      service.ensure_updated_recurrence!

      service.save!

      user.addresses << address
      user.create_first_payment_provider!(service_params[:payment_method_id])
      user.ensure_first_payment!(service_params)

      service.book_aliada

      user.send_welcome_email
      return service
    end
  end

  # We can't use the name 'update' because thats a builtin method
  def update_existing!(service_params)
    ActiveRecord::Base.transaction do
      service_params['datetime'] = Service.parse_date_time(service_params)
      self.attributes = service_params.except(:user, :address)

      set_hours_before_after_service
      ensure_not_downgrading!
      ensure_updated_recurrence!

      reschedule! if needs_rescheduling?
      save!
    end
  end

  def needs_rescheduling?
    return estimated_hours_changed? ||
           datetime_changed? ||
           aliada_id_changed?
  end

  # We don't want the users to go from a recurrent to a one time
  # the code doesnt handle that case and the business does not want that
  def ensure_not_downgrading!
    if service_type_id_changed?
      previous_service_type = ServiceType.find(service_type_id_was)
      current_service_type = ServiceType.find(service_type_id)

      if previous_service_type.recurrent? && current_service_type.one_timer?
        raise AliadaExceptions::ServiceDowgradeImpossible
      end
    end
  end

  def reschedule!
    available_after = starting_datetime_to_book_services

    finder = AvailabilityForService.new(self, available_after, aliada_id: self.aliada_id)

    service_schedules = self.schedules.after_datetime(available_after)
    # The user might have used his/her own schedules
    finder.inject_availability(service_schedules)

    aliadas_availability = finder.find

    raise AliadaExceptions::AvailabilityNotFound if aliadas_availability.empty?

    aliada_availability = AliadaChooser.choose_availability(aliadas_availability, self)

    aliada_availability.book(self)

    # We might have not used some or all those schedules the service has so enable them
    aliada_availability.enable_unused_schedules(service_schedules)
  end

  def update_recurrence!
    if self.recurrence
      self.recurrence.update_attributes!(periodicity: service_type.periodicity,
                                         total_hours: total_hours,
                                         hour: beginning_datetime.hour,
                                         weekday: datetime.weekday)
    end
  end

  def one_time_schedule_intervals
    ScheduleInterval.build_from_range(beginning_datetime, ending_datetime)
  end
   
  def next_day_of_recurrence(starting_after_datetime)
    next_day = starting_after_datetime.change(hour: self.beginning_datetime.hour)
    day = self.datetime

    while next_day.wday != day.wday
      next_day += 1.day
    end

    next_day
  end

  def recurrent_schedule_intervals(starting_after_datetime)
    recurrence_days = self.days_count_to_end_of_recurrency(starting_after_datetime)
    starting_datetime = next_day_of_recurrence(starting_after_datetime)
    schedules_intervals = []

    recurrence_days.times do |i|
      ending_datetime = starting_datetime + total_hours.hours

      schedules_intervals.push(ScheduleInterval.build_from_range(starting_datetime, ending_datetime)) if starting_datetime < horizon

      starting_datetime += periodicity.day
    end
    schedules_intervals
  end

  # To build schedules we must know where do we start
  # because services are booked at an specific range
  def requested_schedules(starting_after_datetime)
    requested_intervals(starting_after_datetime).inject([]) { |schedules, interval| interval.schedules + schedules }.sort.reverse
  end

  def requested_intervals(starting_after_datetime)
    if service_type.recurrent?
      recurrent_schedule_intervals(starting_after_datetime)
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
    end_of_aliadas_day = beginning_of_aliadas_day + Setting.businessday_hours.hours

    found = Time.iterate_in_hour_steps(beginning_of_aliadas_day, end_of_aliadas_day).any? do |current_datime|
      current_datime.hour == self.datetime.hour
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

    configure :extra_services do
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
