class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['not-available','No disponible'],
    ['busy','Ocupada'],
    ['on-transit','En movimiento'],
  ]

  validates_presence_of [:user_id, :datetime, :status]
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[0] } }

  belongs_to :zone
  belongs_to :aliada, -> {where(role: 'aliada')}, class_name: 'User', foreign_key: :user_id
  belongs_to :service

  scope :available, -> {where(status: 'available')}
  scope :in_zone, -> (zone) { where(zone: zone) }
  scope :in_datetimes, -> (datetimes) { where(datetime: datetimes) }

  state_machine :status, :initial => 'available' do
    transition 'available' => 'busy', on: :move_to_busy
  end

  after_initialize :default_values

  def aliada_id
    user_id
  end

  private
    def default_values
      self.status ||= "available"
    end

end
