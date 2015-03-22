class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['booked','Reservado para un servicio'],
    ['busy','Ocupada'],
    ['padding','Horas de colchon entre servicios'],
  ]

  # Validations
  validates_presence_of [:datetime, :status, :aliada_id]
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[0] } }
  validate :schedule_within_working_hours

  # Associations
  belongs_to :aliada 
  belongs_to :service
  belongs_to :recurrence
  has_and_belongs_to_many :zones

  # Scopes
  scope :busy_candidate, -> { where(status: ['booked','available']) }
  scope :available, -> { where(status: 'available') }
  scope :busy, -> { where(status: 'busy') }
  scope :booked, -> {  where(status: 'booked') }
  scope :padding, -> {  where(status: 'padding') }
  scope :in_zone, -> (zone) { joins(:zones).where("schedules_zones.zone_id = ?", zone.id) }
  scope :in_the_future, -> { where("datetime >= ?", Time.zone.now) }
  scope :in_or_after_datetime, ->(starting_datetime) { where("datetime >= ?", starting_datetime) }
  scope :after_datetime, ->(datetime) { where("datetime > ?", datetime) }
  scope :for_aliada_id, ->(aliada_id) { where("schedules.aliada_id = ?", aliada_id) }
  scope :in_or_before_datetime, ->(datetime) { where("datetime <= ?", datetime) }
  scope :ordered_by_aliada_datetime, -> { order(:aliada_id, :datetime) }
  scope :for_booking, ->(zone, starting_datetime) { in_zone(zone).in_or_after_datetime(starting_datetime).ordered_by_aliada_datetime }

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
    transition 'booked' => 'available', on: :enable_booked
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

  def schedule_within_working_hours
    message = 'No podemos registrar una hora de servicio que empieza o termina fuera del horario de trabajo'

    beginning_of_aliadas_day = Time.now.utc.change(hour: Setting.beginning_of_aliadas_day)
    end_of_aliadas_day = beginning_of_aliadas_day + Setting.businessday_hours.hours

    found = Time.iterate_in_hour_steps(beginning_of_aliadas_day, end_of_aliadas_day).any? do |current_datime|
      current_datime.hour == self.datetime.hour
    end

    errors.add(:datetime, message) unless found
  end

  rails_admin do
    label_plural 'horas de servicio'
    navigation_label 'Operación'
    navigation_icon 'icon-calendar'

    configure :datetime do
      # pretty_value do
      #   value.in_time_zone('Mexico City')
      # end
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
