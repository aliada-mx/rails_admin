# -*- encoding : utf-8 -*-
class Service < ActiveRecord::Base
  include Presenters::ServicePresenter
  include AliadaSupport::DatetimeSupport
  include Mixins::RailsAdminModelsHelpers
  include Mixins::ServiceRecurrenceMixin

  has_paper_trail

  STATUSES = [
    ['Creado','created'],
    ['Aliada asignada', 'aliada_assigned'],
    ['Sin aliada', 'aliada_missing'],
    ['Terminado', 'finished'],
    ['Pagado', 'paid'],
    ['Cancelado', 'canceled'],
    ['Cancelado a tiempo', 'canceled_in_time'],
    ['Cancelado a destiempo', 'canceled_out_of_time']
  ]

  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[1] } }
  # accessors for forms
  attr_accessor :postal_code, :payment_method_id, :conekta_temporary_token, :timezone, :hour, :weekday

  belongs_to :address
  belongs_to :user, inverse_of: :services, foreign_key: :user_id
  belongs_to :unscoped_user, foreign_key: :user_id
  belongs_to :aliada, inverse_of: :services, foreign_key: :aliada_id
  belongs_to :payment_method
  belongs_to :recurrence
  belongs_to :service_type
  belongs_to :zone
  has_many :extra_services
  has_many :extras, through: :extra_services
  has_many :schedules, ->{ order(:datetime ) }
  has_many :tickets, as: :relevant_object
  has_many :payments, as: :payeable
  has_many :paypal_charges, as: :payable
  has_many :scores, -> { order(:updated_at) }
  has_many :debts

  # Scopes
  scope :in_the_past, -> { where("datetime < ?", Time.zone.now) }
  scope :in_or_after_datetime, ->(starting_datetime) { where("datetime >= ?", starting_datetime) }
  scope :in_the_future, -> { where("datetime >= ?", Time.zone.now) }
  scope :from_today_to_the_future, -> { where("datetime >= ?", Time.zone.now.beginning_of_aliadas_day)  }
  scope :not_ids, ->(ids) { where("services.id NOT IN ( ? )", ids) }
  scope :on_day, -> (datetime) { where('datetime >= ?', datetime.beginning_of_day).where('datetime <= ?', datetime.end_of_day) } 
  scope :canceled, -> { where("services.status = 'canceled_in_time' OR services.status = 'canceled_out_of_time'", 'canceled') }
  scope :finished, -> { where("services.status = 'finished'") }
  scope :not_canceled, -> { where("services.status != 'canceled_in_time' AND services.status != 'canceled_out_of_time' AND services.status != 'canceled'") }
  scope :ordered_by_created_at, -> { order(:created_at) }
  scope :ordered_by_datetime, -> { order(:datetime) }
  scope :with_recurrence, -> { where('services.recurrence_id IS NOT ?', nil) }
  scope :join_users_and_aliadas, -> { joins('INNER JOIN users ON users.id = services.user_id OR users.id = services.aliada_id') }

  # Rails admin tabs
  scope 'mañana', -> { on_day(Time.zone.now.in_time_zone('Mexico City').beginning_of_aliadas_day + 1.day).not_canceled }
  scope :todos, -> { }
  scope :one_timers, -> { where(service_type: ServiceType.one_time ) }
  scope :recurrent, -> { where(service_type: ServiceType.recurrent ) }
  scope :con_horas_reportadas, -> { where('(aliada_reported_begin_time IS NOT NULL AND aliada_reported_end_time IS NOT NULL) OR hours_worked IS NOT NULL') }
  scope :cobro_fallido, -> { joins(:debts).where('debts.service_id = services.id')
                                          .where('services.status != ?','paid') }

  scope :confirmados, -> { where('services.confirmed IS TRUE') }
  scope :sin_confirmar, -> { where('services.confirmed IS NOT TRUE') }

  # Validations
  validate :datetime_is_hour_o_clock
  validate :datetime_within_working_hours
  validate :service_type_exists
  validates_presence_of :address, :user, :estimated_hours, :service_type, :datetime

  # Callbacks
  after_initialize :set_defaults
  after_create :ensure_zone!

  # TODO: Fix validations, it is only working with :created
  # State machine
  state_machine :status, :initial => 'created' do
    transition 'created' => 'aliada_assigned', :on => :assign
    transition 'created' => 'aliada_missing', :on => :mark_as_missing
    transition ['finished', 'aliada_assigned' ] => 'paid', :on => :pay
    transition ['created', 'aliada_assigned'] => 'finished', :on => :finish
    
    transition (all - ['finished', 'paid']) => 'canceled_in_time', :on => :cancel_in_time
    transition (all - ['finished', 'paid']) => 'canceled_out_of_time', :on => :cancel_out_of_time
    
    after_transition :on => :mark_as_missing, :do => :create_aliada_missing_ticket

    after_transition on: :assign do |service, transition|
      aliada = transition.args.first

        service.aliada = aliada
      service.save!
    end

    before_transition on: [ :cancel_in_time, :cancel_out_of_time ] do |service, transition|
      service.enable_schedules!
    end

    after_transition on: :pay do |service, transition|
      service.send_billing_receipt_email

      service.billed_hours = service.billable_hours
      service.save!
    end

    after_transition on: :finish do |service, transition|
      if service.bill_by_reported_hours?
        hours = service.reported_hours
        if hours < 3
          service.billable_hours = 3
        else
          service.billable_hours = hours
        end
        service.save!
      end
    end
  end

  # Ask service_type to answer recurrent? method for us
  delegate :next_service, to: :recurrence
  delegate :recurrent?, to: :service_type
  delegate :one_timer?, to: :service_type
  delegate :one_timer_from_recurrent?, to: :service_type
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
    Ticket.create_error(relevant_object: self,
                        category: 'conekta_charge_failure',
                        message: "No se pudo realizar cargo de #{amount} a la tarjeta de #{user.first_name} #{user.last_name}. #{error.message_to_purchaser}")
  end
  
  def canceled?
    return self.canceled_in_time? || self.canceled_out_of_time? || self.status == 'canceled'
  end

  def cancel
    if should_charge_cancelation_fee
      cancel_out_of_time
    else
      cancel_in_time
    end
  end
  
  def cost
    if owed?
      amount_owed
    elsif paid?
      billed_hours * service_type.price_per_hour
    elsif finished?
      amount_to_bill
    else
      estimated_hours * service_type.price_per_hour
    end
  end
  alias_method :amount, :cost

  def in_the_past?
    self.datetime_was < Time.zone.now
  end

  def in_the_future?
    self.datetime > Time.zone.now
  end

  # Callbacks
  def set_defaults
    self.status ||= 'created' if self.respond_to? :status
    set_hours_before_after_service
  end

  def set_hours_before_after_service
    self.hours_after_service ||= Setting.padding_hours_between_services
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

    recurrence_attributes = self.shared_attributes.except('service_type_id', 'price', 'recurrence_id')
    recurrence_attributes.merge!({'periodicity' => service_type.periodicity,
                                 'hour' => tz_aware_datetime.hour,
                                 'weekday' => tz_aware_datetime.weekday })

    
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
                          category: 'availability_missing',
                          relevant_object: self
  end

  def total_hours
    estimated_hours + hours_after_service
  end

  def book_one_timer(aliada_id: nil)
    available_after = starting_datetime_to_book_services

    # TODO create a method to reschedule a one time
    original_service_type_id = self.service_type_id
    self.service_type_id = ServiceType.one_time.id

    aliadas_availability = AvailabilityForService.find_aliadas_availability(self, available_after, aliada_id: aliada_id)

    self.service_type_id = original_service_type_id

    raise AliadaExceptions::AvailabilityNotFound if aliadas_availability.empty?

    aliada_availability = AliadaChooser.choose_availability(aliadas_availability, self)
    
    self.aliada = aliada_availability.aliada
    self.hours_after_service = aliada_availability.padding_count
    self.save!

    aliada_availability.book(self)
  end

  def book_an_aliada(aliada_id: nil)
    available_after = starting_datetime_to_book_services

    aliadas_availability = AvailabilityForService.find_aliadas_availability(self, available_after, aliada_id: aliada_id)

    raise AliadaExceptions::AvailabilityNotFound if aliadas_availability.empty?

    aliada_availability = AliadaChooser.choose_availability(aliadas_availability, self)
    
    self.aliada = aliada_availability.aliada
    self.save!

    aliada_availability.book(self)
  end

  def should_charge_cancelation_fee
    in_less_than_24_hours
  end

  def in_less_than_24_hours
    # While creating a service there is no datetime 
    # and rails admin blows up so we must check
    now = Time.zone.now
    if datetime && datetime > now
      in_24_hours = now + 24.hours

      datetime <= in_24_hours
    else
      false
    end
  end

  def reported_hours
    if bill_by_hours_worked?
      hours_worked
    elsif bill_by_reported_hours?
      (self.aliada_reported_end_time - self.aliada_reported_begin_time) / 3600.0
    end
  end
  
  #calculates the price to be charged for a service
  def amount_by_reported_hours
    amount = reported_hours * service_type.price_per_hour
    if amount > 0 then amount else 0 end
  end

  def amount_by_billable_hours
    billable_hours * service_type.price_per_hour
  end

  def bill_by_reported_hours?
    (aliada_reported_begin_time.present? && aliada_reported_end_time.present?) || hours_worked.present?
  end

  def bill_by_hours_worked?
    hours_worked.present?
  end

  def bill_by_billable_hours?
    billable_hours.present? && !billable_hours.zero?
  end

  def amount_to_bill
    if self.canceled_in_time?
      0
    elsif self.canceled_out_of_time?
      100
    #Billable hours has preference over reported hours so Operations can override an aliada  
    elsif bill_by_billable_hours?

      amount_by_billable_hours.ceil

    elsif bill_by_reported_hours?

      amount_by_reported_hours.ceil

    else
      0
    end
  end

  def enable_schedules!
    self.schedules.in_the_future.map(&:enable_booked)
  end

  def charge!
    return if paid? || canceled? || amount_to_bill.zero?

    ActiveRecord::Base.transaction do

      amount = amount_to_bill
      product = OpenStruct.new({amount: amount,
                                description: 'Servicio aliada',
                                category: 'service',
                                id: id})
      
      payment = user.charge!(product, self)

      if payment && payment.paid?
        pay!
      end
    end
  end

  def send_billing_receipt_email
    UserMailer.billing_receipt(self.user, self).deliver
  end

  def charge_cancelation_fee!
    return if self.cancelation_fee_charged

    cancelation_fee = OpenStruct.new({amount: Setting.too_late_cancelation_fee,
                                      description: "Cancelación tardía del servicio del #{friendly_datetime} con #{aliada.name}",
                                      category: 'cancelation_fee',
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
      chosen_aliada_id = service_params[:aliada_id].to_i

      address = user.default_address

      service = Service.new(service_params.except!(:user, :address))

      service.address = address
      service.user = user
      service.ensure_updated_recurrence!

      service.save!

      service.book_an_aliada(aliada_id: chosen_aliada_id)
      service.ensure_updated_recurrence!

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
      service.ensure_updated_recurrence!

      user.create_promotional_code code_type

      user.send_service_confirmation_pwd(service,password)
      return service
    end
  end

  def not_canceled?
    self.status != 'canceled'
  end

  def user_modified_booking(service_params)
    datetime != service_params[:datetime] ||
    estimated_hours != BigDecimal.new(service_params[:estimated_hours]) ||
    aliada_id != service_params[:aliada_id].to_i
  end


    # Among recurrent services
  def shared_attributes
    self.attributes.select { |key, value| [:entrance_instructions, 
                                           :estimated_hours, 
                                           :hours_after_service,
                                           :rooms_hours,
                                           :address_id,
                                           :bathrooms,
                                           :bedrooms,
                                           :price,
                                           :recurrence_id,
                                           :service_type_id,
                                           :user_id,
                                           :zone_id,
                                           :aliada_id,
                                           :attention_instructions,
                                           :extra_ids,
                                           :cleaning_supplies_instructions,
                                           :equipment_instructions,
                                           :garbage_instructions,
                                           :special_instructions].include? key.to_sym  }

  end

  # We can't use the name 'update' because thats a builtin method
  def update_existing!(service_params)
    ActiveRecord::Base.transaction do
      chosen_aliada_id = service_params[:aliada_id].to_i
      
      service_params['datetime'] = Service.parse_date_time(service_params)

      service_params.except!(:aliada_id) if chosen_aliada_id == 0

      needs_rescheduling = self.user_modified_booking(service_params)

      # The new atributtes will be used by the availability finders
      self.attributes = service_params

      reschedule!(chosen_aliada_id) if needs_rescheduling

      self.save!
    end
  end

  def self.instructions_attributes
    [ :entrance_instructions,
      :rooms_hours,
      :attention_instructions,
      :cleaning_supplies_instructions,
      :equipment_instructions,
      :garbage_instructions, :special_instructions ]
  end

  def cancel_all!
    cancel

    if should_charge_cancelation_fee
      charge_cancelation_fee!
    end
  end

  def reschedule!(aliada_id)
    previous_schedules = self.schedules.in_the_future.to_a

    aliada_availability = book_one_timer(aliada_id: aliada_id)

    # We might have not used some or all those schedules the service had, so enable them back
    current_schedules = aliada_availability.schedules
    unused = previous_schedules - current_schedules
    unused.map(&:enable_booked)
  end

  def other_services
    if recurrent?
      recurrence.services.in_the_future.not_ids(self.id)
    end 
  end
   
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
      current_datime.hour == self.datetime.utc.hour
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
      recurrence.services.not_canceled.in_the_future.pluck(:id)
    else
      [ id ]
    end
  end

  def schedules_count
    schedules.count
  end

  def owed?
    debts.any? { |debt| !debt.paid? }
  end

  def amount_owed
    debts.inject(0) do |total, debt|
      total += debt.amount unless debt.paid?
    end
  end

  attr_accessor :rails_admin_billable_hours_widget
  
  rails_admin do
    label_plural 'servicios'
    navigation_label 'Operación'
    navigation_icon 'icon-home'

    configure :extra_services do
      visible false
    end

    configure :aliada_reported_begin_time do
      read_only true
      pretty_value do
        if value
          object = bindings[:object]

          object.friendly_aliada_reported_begin_time
        end
      end
    end

    configure :aliada_reported_end_time do
      read_only true
      pretty_value do
        if value
          object = bindings[:object]
          object.friendly_aliada_reported_end_time
        end
      end
    end

    list do
      search_scope do
        Proc.new do |scope, query|
          query_without_accents = I18n.transliterate(query)

          scope.merge(UnscopedUser.with_name_phone_email(query_without_accents)).merge(Service.join_users_and_aliadas)
        end
      end

      configure :status do
        queryable false
        filterable true
        visible false
      end

      sort_by :datetime

      field :user_link do
        virtual?
      end

      field :datetime

      field :status

      field :address_map_link

      field :rails_admin_billable_hours_widget do
        virtual?
        formatted_value do
          bindings[:view].render partial: 'rails_admin/main/rails_admin_billable_hours_widget', locals: {field: self, 
                                                                                                         user: bindings[:current_user],
                                                                                                         form: bindings[:form],
                                                                                                         service: bindings[:object]}
          
        end
      end

      field :aliada_webapp_link
      field :aliada_reported_begin_time
      field :aliada_reported_end_time
      field :reported_hours
      field :schedules_count
      field :estimated_hours
      field :recurrence
      field :created_at

      scopes ['mañana', :todos, :confirmados, :sin_confirmar, :con_horas_reportadas, :cobro_fallido]
    end

    edit do
      field :created_at

      field :status
      field :datetime
      field :user
      field :aliada
      field :address
      field :service_type
      field :recurrence

      field :cancelation_fee_charged

      group :horas_de_servicio do
        field :estimated_hours
        field :aliada_reported_begin_time
        field :aliada_reported_end_time

        field :billable_hours
        field :billed_hours do
          read_only true
          visible do
            value.present? && !value.zero?
          end
        end

        field :hours_after_service
        field :rooms_hours
        field :schedules

        field :hours_worked do
          label 'Horas trabajadas'
          help 'Reportadas por la aliada'
        end
      end

      field :tickets

      group :detalles_al_registrar do
        active false
        field :bathrooms
        field :bedrooms
        field :special_instructions
        field :cleaning_supplies_instructions
        field :garbage_instructions
        field :attention_instructions
        field :equipment_instructions
        field :forbidden_instructions
        field :entrance_instructions
      end
    end
  end
end
