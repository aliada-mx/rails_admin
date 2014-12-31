class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['busy','Ocupada'],
    ['on-transit','En movimiento'],
  ]

  belongs_to :zone
  belongs_to :user, -> {where(role: 'aliada')}
  belongs_to :service

  def self.available_in_zone(zone)
    Schedule.where(zone: zone, status: 'available')
  end
end
