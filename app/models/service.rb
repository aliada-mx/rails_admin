# -*- coding: utf-8 -*-
class Service < ActiveRecord::Base
  include Presenters::ServicePresenter
  include AliadaSupport::DatetimeSupport
  include Mixins::RailsAdminModelsHelpers

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
  scope :not_ids, ->(ids) { where("services.id NOT IN ( ? )", ids) }
  scope :on_day, -> (datetime) { where('datetime >= ?', datetime.beginning_of_day).where('datetime <= ?', datetime.end_of_day) } 
  scope :canceled, -> { where('services.status = ?', 'canceled') }
  scope :not_canceled, -> { where('services.status != ?', 'canceled') }
  scope :ordered_by_created_at, -> { order(:created_at) }
  scope :ordered_by_datetime, -> { order(:datetime) }
  scope :with_recurrence, -> { where('services.recurrence_id IS NOT ?', nil) }
  # Rails admin tabs
  scope :del_dia, -> { on_day(Time.zone.now + 1.day).not_canceled }
  scope :todos, -> do 
    find_by_sql all.joins(:user).to_sql.gsub(
      'INNER JOIN "users" ON "users"."id" = "services"."user_id" AND (users.role in (\'client\',\'admin\'))',
      'INNER JOIN "users" ON "users"."id" = "services"."user_id" OR "users"."id" = "services"."aliada_id" AND (users.role in (\'client\',\'admin\', \'aliada\'))',
    ) 
  end


  scope :confirmados, -> { where('services.confirmed IS TRUE') }
  scope :sin_confirmar, -> { where('services.confirmed IS NOT TRUE') }

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
    transition 'finished' => 'paid', :on => :pay
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
      service.enable_schedules!
    end
  end

  # Ask service_type to answer recurrent? method for us
  delegate :recurrent?, to: :service_type
  delegate :one_timer?, to: :service_type
  delegate :periodicity, to: :service_type
  delegate :wdays_count_to_end_of_recurrency, to: :recurrence

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

  def create_charge_failed_ticket(user, amount, error)
    Ticket.create_error(relevant_object_id: self.id,
                        relevant_object_type: 'Service',
                        message: "No se pudo realizar cargo de #{amount} a la tarjeta de #{user.first_name} #{user.last_name}. #{error.message_to_purchaser}")
  end
  
  def cost
    estimated_hours_with_extras * service_type.price_per_hour
  end

  def extras_hours
    extras.inject(0){ |hours,extra| hours += extra.hours || 0 }
  end

  def estimated_hours_without_extras
    (estimated_hours || 0) - extras_hours
  end

  def estimated_hours_with_extras
    (estimated_hours || 0) + extras_hours
  end


  # Callbacks
  def set_defaults
    self.status ||= 'created' if self.respond_to? :status
    set_hours_before_after_service
  end

  def set_hours_before_after_service
    self.hours_after_service = Setting.padding_hours_between_services
  end

  def self.parse_date_time(params)
    datetime = ActiveSupport::TimeZone[self.timezone].parse("#{params[:date]} #{params[:time]}")
    if datetime.dst?
      datetime += 1.hour
    end
    datetime
  end

  def ensure_updated_recurrence!
    return unless recurrent?

    recurrence_attributes = {user_id: user_id,
                             periodicity: service_type.periodicity,
                             total_hours: total_hours,
                             hour: tz_aware_datetime.hour,
                             weekday: tz_aware_datetime.weekday }

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
    estimated_hours + hours_after_service
  end


  def ending_datetime
    datetime + total_hours.hours
  end

  def book_an_aliada(aliada_id: nil)
    available_after = starting_datetime_to_book_services

    finder = AvailabilityForService.new(self, available_after, aliada_id: aliada_id)

    aliadas_availability = finder.find

    raise AliadaExceptions::AvailabilityNotFound if aliadas_availability.empty?

    aliada_availability = AliadaChooser.choose_availability(aliadas_availability, self)

    aliada_availability.book_new(self)
  end

  # Among recurrent services
  def shared_attributes
    self.attributes.except('id',
                           'datetime',
                           'aliada_reported_being_time',
                           'aliada_reported_end_time',
                           'billed_hours',
                           'created_at',
                           'updated_at')
  end


  def in_less_than_24_hours
    if datetime
      in_24_hours = Time.zone.now + 24.hours

      datetime < in_24_hours
    else
      false
    end
  end
  
  #calculates the price to be charged for a service
  def amount_to_bill
    hours = self.aliada_reported_end_time.hour - self.aliada_reported_begin_time.hour
    minutes = self.aliada_reported_end_time.min - self.aliada_reported_begin_time.min 
    if hours < 3 && hours > 0
    then
      hours = 3
      minutes = 0
    end
    amount = (hours*(self.service_type.price_per_hour))+(minutes * ((self.service_type.price_per_hour)/60.0))
    
   
    if amount > 0 && (self.aliada_reported_end_time.to_date === self.aliada_reported_begin_time.to_date)
      return amount
    else
      return 0
    end
  end

  def enable_schedules!
    self.schedules.in_the_future.map(&:enable_booked)
  end

  def charge!
    return if paid?

    amount = self.amount_to_bill
    product = OpenStruct.new({amount: amount,
                              description: 'Servicio aliada',
                              id: id})
    
    payment = user.charge!(product, self)

    if payment && payment.paid?
      pay!
    end
  end

  def create_double_charge_ticket
    Ticket.create_warning message: "Se intentó cobrar un servicio ya cobrado", 
                          action_needed: "Deselecciona el servicio al cobrar",
                          relevant_object: self
  end

  def charge_cancelation_fee!
    return if self.cancelation_fee_charged

    amount = Setting.too_late_cancelation_fee

    cancelation_fee = OpenStruct.new({amount: amount,
                                      description: "Cancelación tardía del servicio del #{friendly_datetime} en aliada.mx",
                                      id: self.id})

    payment = user.charge!(cancelation_fee , self)

    if payment && payment.paid?
      self.cancelation_fee_charged = true
      self.save!
    end
  end

  def self.create_new!(service_params, user)
    ActiveRecord::Base.transaction do
      service_params[:datetime] = Service.parse_date_time(service_params)

      address = user.default_address
      service = Service.new(service_params.except!(:user, :address))

      service.address = address
      service.user = user
      service.ensure_updated_recurrence!

      service.save!

      service.book_an_aliada

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
      code_type = CodeType.find_by(name: "personal")
      password = user.password

      service.address = address
      service.user = user
      service.set_hours_before_after_service
      service.ensure_updated_recurrence!

      service.save!

      user.addresses << address
      user.create_first_payment_provider!(service_params[:payment_method_id])
      user.ensure_first_payment!(service_params, service)
      user.save!

      service.book_an_aliada

      user.create_promotional_code code_type

      user.send_service_confirmation_pwd(service,password)
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

  # Cancel this service and all related through the recurrence
  def cancel_all!
    ActiveRecord::Base.transaction do
      cancel!

      if recurrent?
        recurrence.services.in_the_future.each do |service|
          next if self.id == service.id
          service.cancel!
        end
        recurrence.deactivate!
        recurrence.save!
      end

      if in_less_than_24_hours
        charge_cancelation_fee!
      end
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
    previous_services = self.other_services.to_a
    
    ensure_updated_recurrence!

    aliada_availability = book_an_aliada(aliada_id: self.aliada_id)

    # We might have not used some or all those schedules the service had, so enable them back
    aliada_availability.enable_unused_schedules

    # Clear up other services
    previous_services.map(&:cancel)
  end

  def other_services
    if recurrent?
      recurrence.services.in_the_future.not_ids(self.id)
    end 
  end

  # To build schedules we must know where do we start
  # because services are booked at an specific range
  def requested_schedules
    ScheduleInterval.build_from_range(datetime, ending_datetime, elements_for_key: estimated_hours, conditions:{ aliada_id: aliada_id })
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
  
  def send_aliada_changed_email
    ServiceMailer.aliada_changed(self).deliver!
  end

  def send_hour_changed_email
    ServiceMailer.hour_changed(self).deliver!
  end


  def send_untimely_cancellation_email
    ServiceMailer.untimely_cancelation(self).deliver!
  end
  
  def send_address_changed_email(previous_address)
    ServiceMailer.address_changed(self,previous_address).deliver!
  end
  
  def send_timely_cancelation_email
    ServiceMailer.timely_cancelation(self).deliver!
  end
  
  def send_reminder_email
    ServiceMailer.reminder(self).deliver!
  end

  def related_services_ids
    if recurrent? && recurrence.present?
      recurrence.services.pluck(:id)
    else
      [ id ]
    end
  end

  rails_admin do
    label_plural 'servicios'
    navigation_label 'Operación'
    navigation_icon 'icon-home'

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

      field :aliada_link do
        virtual?
      end

      field :aliada do
        searchable [{users: :first_name },
                    {users: :last_name },
                    {users: :email},
                    {users: :phone}]
        queryable true
        filterable true
      end

      field :recurrence

      field :created_at

      field :address

      scopes [:del_dia, :todos, :confirmados, :sin_confirmar]
    end
  end
end
