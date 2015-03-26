class Recurrence < ActiveRecord::Base
  include AliadaSupport::DatetimeSupport

  OWNERS = [
    'aliada',
    'user'
  ]

  STATUSES = [
    ['active', 'Activa'],
    ['inactive', 'Inactiva']
  ]

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

  def base_service
    services.with_recurrence.ordered_by_created_at.first
  end

  def owner_enum
    OWNERS
  end

  def wday
    Time.weekdays.select{ |day| day[0] == weekday }.first.second
  end

  def timezone
    'Mexico City'
  end

  def next_day_of_recurrence(starting_after_datetime)
    next_day = starting_after_datetime.change(hour: hour)

    while next_day.wday != wday
      next_day += 1.day
    end

    next_day
  end

  # Starting the next recurrence day how many days we'll provide service until the horizon
  def wdays_count_to_end_of_recurrency(starting_after_datetime)
    wdays_until_horizon(wday, starting_from: next_day_of_recurrence(starting_after_datetime))
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
