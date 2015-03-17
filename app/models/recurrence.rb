class Recurrence < ActiveRecord::Base
  OWNERS = [
    'aliada',
    'user'
  ]
  include AliadaSupport::DatetimeSupport

  validates_presence_of [:weekday, :hour]
  validates :weekday, inclusion: {in: Time.weekdays.map{ |days| days[0] } }
  validates :hour, inclusion: {in: [*0..23] } 
  validates_numericality_of :periodicity, greater_than: 1

  belongs_to :user
  belongs_to :aliada
  belongs_to :zone
  has_many :services

  has_many :services

  default_scope { where(owner: 'user') }

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

  rails_admin do
    label_plural 'recurrencias'
    navigation_label 'Operación'
    navigation_icon 'icon-repeat'

    configure :owner do
      visible false
    end
  end
end
