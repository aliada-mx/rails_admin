class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['not-available','No disponible'],
    ['busy','Ocupada'],
    ['on-transit','En movimiento'],
  ]

  validates_presence_of [:user_id, :datetime, :status]

  belongs_to :zone
  belongs_to :aliada, -> {where(role: 'aliada')}, class_name: 'User', foreign_key: :user_id
  belongs_to :service

  scope :available_in_zone, -> (zone) { where(zone: zone, status: 'available') }

  state_machine :status, :initial => 'available' do

  end

  after_initialize :default_values

  private
    def default_values
      self.status ||= "available"
    end

end
