class Schedule < ActiveRecord::Base
  STATUSES = [
    ['available','Disponible'],
    ['not-available','No disponible'],
    ['busy','Ocupada'],
    ['on-transit','En movimiento'],
  ]

  validates :datetime, presence: true, uniqueness: { scope: [:user_id, :datetime] }
  validates_presence_of [:datetime, :status]
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[0] } }

  belongs_to :zone
  belongs_to :aliada, -> {where(role: 'aliada')}, class_name: 'User', foreign_key: :user_id
  belongs_to :service

  scope :available, -> {where(status: 'available')}
  scope :in_zone, -> (zone) { where(zone: zone) }
  scope :in_datetimes, -> (datetimes) { where(datetime: datetimes) }
  scope :ordered_by_user_datetime, -> { order(:user_id, :datetime) }

  state_machine :status, :initial => 'available' do
    transition 'available' => 'busy', on: :move_to_busy
  end

  after_initialize :default_values

  def aliada_id
    user_id
  end

  def self.build_recurrent(datetime, hours, aliada)

  end

  def self.build_one_timer(datetime, hours, aliada)
    schedule_interval = ScheduleInterval.build_from_range(datetime, datetime + hours.hours, use_persisted: true)
    if schedule_interval.valid?
      return schedule_interval.persist_schedules!
    else
      return false
    end
  end

  private
    def default_values
      # If we query for schedules with select and we dont
      # include the status we can't give it a default value
      if self.respond_to? :status
        self.status ||= "available"
      end
    end
end
