class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['booked','Reservado para un servicio'],
    ['busy','Ocupada'],
    ['on-transit','En movimiento'],
  ]

  validates_presence_of [:datetime, :status]
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[0] } }

  belongs_to :zone
  belongs_to :aliada
  belongs_to :service

  scope :available, -> {where(status: 'available')}
  scope :booked, -> {where(status: 'booked')}
  scope :in_zone, -> (zone) { where(zone: zone) }
  scope :in_the_future, -> (datetimes) { where("datetime > ?", Time.zone.now) }
  scope :ordered_by_aliada_datetime, -> { order(:aliada_id, :datetime) }

  state_machine :status, :initial => 'available' do
    transition 'available' => 'booked', on: :book
  end

  after_initialize :default_values


  private
    def default_values
      # If we query for schedules with select and we dont
      # include the status we can't give it a default value
      if self.respond_to? :status
        self.status ||= "available"
      end
    end
end
