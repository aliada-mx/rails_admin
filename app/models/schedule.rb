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

  # state_machine :state, :initial => :available do

  # end

  def self.create_schedule_interval(start_date, end_date, aliada)
    schedules = []
    (start_date.to_i .. end_date.to_i).step(1.hour) do |date|
      schedules.push(create(datetime: Time.at(date), user: aliada))
    end

    ScheduleInterval.new(schedules)
  end
end
