class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['not-available','No disponible'],
    ['busy','Ocupada'],
    ['on-transit','En movimiento'],
  ]

  validates_presence_of [:user, :datetime]

  belongs_to :zone
  belongs_to :user, -> {where(role: 'aliada')}
  belongs_to :service

  scope :available_in_zone, -> (zone) { where(zone: zone, status: 'available') }

  state_machine :status, :initial => :available do

  end

end
