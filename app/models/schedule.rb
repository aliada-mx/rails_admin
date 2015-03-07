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

  state_machine :status, :initial => 'available' do
    transition 'available' => 'booked', on: :book
  end

  after_initialize :set_default_values

  rails_admin do
    label_plural 'horas de servicio'
    navigation_label 'Operación'
    navigation_icon 'icon-calendar'
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
