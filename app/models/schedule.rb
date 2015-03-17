class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['booked','Reservado para un servicio'],
    ['busy','Ocupada'],
    ['on-transit','En movimiento'],
  ]

  # Validations
  validates_presence_of [:datetime, :status, :aliada_id, :zone]
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[0] } }
  validate :schedule_within_working_hours

  # Associations
  belongs_to :zone
  belongs_to :aliada 
  belongs_to :service

  # Scopes
  scope :available, -> { where(status: 'available').where('user_id IS NULL') }
  scope :booked, -> {  where(status: 'booked') }
  scope :in_zone, -> (zone) { where(zone: zone) }
  scope :in_the_future, -> { where("datetime >= ?", Time.zone.now) }
  scope :after_datetime, ->(starting_datetime) { where("datetime >= ?", starting_datetime) }
  scope :ordered_by_aliada_datetime, -> { order(:aliada_id, :datetime) }
  scope :available_for_booking, ->(zone, starting_datetime) { available.in_zone(zone).after_datetime(starting_datetime).ordered_by_aliada_datetime }

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
    transition 'booked' => 'available', on: :enable_booked
    transition 'available' => 'booked', on: :book

    after_transition on: :enable_booked do |schedule, transition|
      schedule.service_id = nil
      schedule.save!
    end
  end

  after_initialize :set_default_values

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
      pretty_value do
        value.in_time_zone('Mexico City')
      end
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
