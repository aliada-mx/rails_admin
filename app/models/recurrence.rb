class Recurrence < ActiveRecord::Base
  include AliadaSupport::DatetimeSupport

  has_paper_trail

  OWNERS = [
    'aliada',
    'user'
  ]

  STATUSES = [
    ['Activa','active'],
    ['Inactiva','inactive']
  ]

  validates_presence_of [:weekday, :hour]
  validates :weekday, inclusion: {in: Time.weekdays.map{ |days| days[0] } }
  validates :hour, inclusion: {in: [*0..23] } 
  validates_numericality_of :periodicity, greater_than: 1
  validates :status, inclusion: {in: STATUSES.map{ |pairs| pairs[1] } }

  belongs_to :user
  belongs_to :aliada
  belongs_to :zone
  has_many :services, inverse_of: :recurrence 
  has_many :schedules

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  default_scope { where(owner: 'user') }

  state_machine :status, :initial => 'active' do
    transition 'active' => 'inactive', :on => :deactivate
    transition 'inactive' => 'active', :on => :activate
  end

  def status_enum
    STATUSES
  end

  def name
    "#{weekday_in_spanish} de #{hour} a #{ending_hour} (#{id})"
  end

  def base_service
    services.with_recurrence.ordered_by_created_at.first
  end

  def next_service
    services.ordered_by_datetime.where('datetime > ?', Time.zone.now).first
  end

  def ending_hour
    hour + total_hours
  end

  def owner_enum
    OWNERS
  end

  def weekday_enum
    Time.weekdays.map {|weekday_trio| [weekday_trio.third, weekday_trio.first]}
  end

  def wday
    Time.weekdays.select{ |day| day[0] == weekday }.first.second
  end

  def weekday_in_spanish
    weekday_to_spanish(weekday)
  end

  def timezone
    'Mexico City'
  end

  def in_dst?
    Time.zone.now.in_time_zone(self.timezone).dst?
  end

  def now_in_timezone
    time_obj = Time.zone.now.in_time_zone(self.timezone)
    if in_dst?
      time_obj += 1.hour
    end
    time_obj
  end

  def weekday_now
    time_obj = now_in_timezone
    time_obj.weekday
  end

  def utc_hour(utc_date)
    Chronic.time_class= ActiveSupport::TimeZone[self.timezone]
    time_obj = Chronic.parse("#{utc_date.strftime('%F')} #{self.hour}")
    if time_obj.dst?
      time_obj += 1.hour
    end
    time_obj.utc.hour
  end

  def utc_weekday(utc_date)
    if self.utc_hour(utc_date) <= 23 and self.utc_hour(utc_date) > 6
      return self.weekday
    else
      return Time.next_weekday self.wday  
    end
  end

  def tz_aware_hour(utc_datetime)
    utc_to_timezone(utc_datetime, self.timezone).hour
  end

  def tz_aware_hour(utc_datetime)
    utc_to_timezone(utc_datetime, self.timezone).weekday
  end

  def next_recurrence_now_in_time_zone
    if self.weekday == now_in_timezone.weekday
      return now_in_timezone
    else
      next_day = now_in_timezone
      while self.wday != next_day.wday
        next_day += 1.day
      end
      return next_day
    end
  end

  def next_recurrence_with_hour_now_in_time_zone
    next_recurrence_now_in_time_zone.change(hour: self.hour)
  end

  def next_recurrence_with_hour_now_in_utc
    time_obj = next_recurrence_with_hour_now_in_time_zone
    if time_obj.dst?
      time_obj += 1.hour
    end
    time_obj.utc
  end

  # TODO: fix
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

    configure :services do
      associated_collection_scope do 
        recurrence = bindings[:object]
        if recurrence.services
          Proc.new { |scope|
            # scoping only the unused placeholders and our own placeholders
            scope.where(recurrence_id: recurrence.id)
          }
        end
      end
    end

    list do

      search_scope do
        Proc.new do |scope, query|
          query_without_accents = I18n.transliterate(query)

          scope.merge(UnscopedUser.with_name_phone_email(query_without_accents))
        end
      end

      field :user do 
        searchable [{users: :first_name }, {users: :last_name }, {users: :email}, {users: :phone}]
        queryable true
        filterable true
      end
      field :aliada
      field :name
      field :total_hours
    end
  end
end
