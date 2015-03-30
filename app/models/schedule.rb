class Schedule < ActiveRecord::Base
  include Mixins::RailsAdminModelsHelpers
  include AliadaSupport::DatetimeSupport
  include Presenters::SchedulePresenter

  STATUSES = [
    ['Disponible','available'],
    ['Reservado para un servicio', 'booked'],
    ['Ocupada','busy'],
    ['Hora de colchon entre servicios', 'padding'],
  ]

  # Validations
  validates_presence_of [:datetime, :status, :aliada_id]
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[1] } }
  validate :schedule_within_working_hours

  # Associations
  belongs_to :user, inverse_of: :schedules, foreign_key: :user_id
  belongs_to :aliada, inverse_of: :schedules, foreign_key: :aliada_id
  belongs_to :service, inverse_of: :schedules
  belongs_to :recurrence
  has_and_belongs_to_many :zones

  # Scopes
  scope :busy_candidate, -> { where(status: ['booked','available']) }
  scope :available, -> { where(status: 'available') }
  scope :busy, -> { where(status: 'busy') }
  scope :booked, -> {  where(status: 'booked') }
  scope :padding, -> {  where(status: 'padding') }
  scope :booked_or_padding, -> {  where(status: ['booked', 'padding' ]) }
  scope :in_zone, -> (zone) { joins(:zones).where("schedules_zones.zone_id = ?", zone.id) }
  scope :in_the_future, -> { where("datetime >= ?", Time.zone.now) }
  scope :in_or_after_datetime, ->(starting_datetime) { where("datetime >= ?", starting_datetime) }
  scope :after_datetime, ->(datetime) { where("datetime > ?", datetime) }
  scope :for_aliada_id, ->(aliada_id) { where("schedules.aliada_id = ?", aliada_id) }
  scope :in_or_before_datetime, ->(datetime) { where("datetime <= ?", datetime) }
  scope :ordered_by_aliada_datetime, -> { order(:aliada_id, :datetime) }
  scope :for_booking, ->(zone, starting_datetime) { in_zone(zone).in_or_after_datetime(starting_datetime).ordered_by_aliada_datetime }
  # alias for rails admin
  scope :disponible, -> { available }
  scope :reservadas, -> { booked }
  scope :todos, -> { }

  scope :previous_aliada_schedule, ->(zone, current_schedule, aliada) { 
    in_zone(zone)
   .where(datetime: current_schedule
   .datetime - 1.hour)
   .ordered_by_aliada_datetime 
   .where(aliada: aliada)
  }

  scope :next_aliada_schedule, ->(zone, current_schedule, aliada) { 
    in_zone(zone)
    .where(datetime: current_schedule
    .datetime + 1.hour)
    .ordered_by_aliada_datetime 
    .where(aliada: aliada)
  }

  state_machine :status, :initial => 'available' do
    transition ['available', 'busy'] => 'booked', on: :book
    transition ['booked', 'busy'] => 'available', on: :enable
    transition ['booked', 'padding'] => 'available', on: :enable_booked
    transition ['available', 'booked'] => 'busy', on: :get_busy
    transition ['booked', 'available'] => 'padding', on: :as_padding

    after_transition on: [:enable_booked, :enable] do |schedule, transition|
      schedule.user_id = nil
      schedule.service_id = nil
      schedule.recurrence_id = nil
      schedule.save!
    end
  end

  after_initialize :set_default_values

  attr_accessor :index # for availability finders to track they schedule position on the main loop
  attr_accessor :original_status # for availability finders because they asume the state is available we keep a record of the original state

  def timezone
    'Mexico City'
  end

  def schedule_within_working_hours
    message = 'No podemos registrar una hora de servicio que empieza o termina fuera del horario de trabajo'

    beginning_of_aliadas_day = Time.now.utc.change(hour: Setting.beginning_of_aliadas_day)
    end_of_aliadas_day = beginning_of_aliadas_day + Setting.businessday_hours.hours

    found = Time.iterate_in_hour_steps(beginning_of_aliadas_day, end_of_aliadas_day).any? do |current_datime|
      current_datime.hour == self.datetime.hour
    end

    errors.add(:datetime, message) unless found
  end

  def status_enum
    STATUSES
  end

  def user_link
    rails_admin_edit_link(user)
  end

  def service_link
    rails_admin_edit_link(service)
  end

  rails_admin do
    label_plural 'horas de servicio'
    navigation_label 'Operación'
    navigation_icon 'icon-calendar'

    configure :datetime do
      pretty_value do
        object = bindings[:object]
        I18n.l(object.tz_aware_datetime, format: :future)
      end
      sort_reverse false
    end

    configure :status do
      queryable true
      filterable true
    end

    list do
      sort_by :datetime

      field :datetime
      field :status
      field :user_link do
        virtual?
      end

      field :aliada do
        searchable [{users: :first_name }, {users: :last_name }, {users: :email}, {users: :phone}]
        queryable true
        filterable true
      end

      field :service_link do
        virtual?
      end

      field :recurrence
      field :created_at

      scopes [:todos, :reservadas, :disponible]
    end

  end

  private
    def set_default_values
      # If we query for schedules with select and we dont
      # include the status we can't give it a default value
      if self.respond_to? :status
        self.status ||= "available"
      end
    end

end
