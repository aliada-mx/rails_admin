class Recurrence < ActiveRecord::Base
  OWNERS = [
    'aliada',
    'user'
  ]

  STATUSES = [
    ['active', 'Activa'],
    ['inactive', 'Inactiva']
  ]

  include AliadaSupport::DatetimeSupport

  validates_presence_of [:weekday, :hour]
  validates :weekday, inclusion: {in: Time.weekdays.map{ |days| days[0] } }
  validates :hour, inclusion: {in: [*0..23] } 
  validates_numericality_of :periodicity, greater_than: 1
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[0] } }

  belongs_to :user
  belongs_to :aliada
  belongs_to :zone
  has_many :services
  has_many :schedules

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  default_scope { where(owner: 'user') }

  state_machine :status, :initial => 'active' do
    transition 'active' => 'inactive', :on => :deactivate
    transition 'inactive' => 'active', :on => :activate
  end

  def owner_enum
    OWNERS
  end

  def wday
    Time.weekdays.select{ |day| day[0] == weekday }.first.second
  end

  def weekday_in_spanish
    Time.weekdays.select{ |day| day[0] == weekday }.first.third
  end

  def timezone
    'Mexico City'
  end

  def utc_hour(utc_date)
    Chronic.time_class= ActiveSupport::TimeZone[self.timezone]
    time_obj = Chronic.parse("#{utc_date.strftime('%F')} #{self.hour}")
    if time_obj.dst?
      time_obj += 1.hour
    end
    time_obj.utc.hour
  end

  rails_admin do
    label_plural 'recurrencias'
    navigation_label 'Operación'
    navigation_icon 'icon-repeat'

    configure :owner do
      visible false
    end
  end
end
