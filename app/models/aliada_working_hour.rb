# -*- encoding : utf-8 -*-
class AliadaWorkingHour < ActiveRecord::Base
  include AliadaSupport::DatetimeSupport
  include Mixins::RecurrenceAliadaWorkingHoursMixin

  has_paper_trail

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
  belongs_to :address

  # Scopes

  scope :ordered_by_created_at, -> { order(:created_at) }
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  state_machine :status, :initial => 'active' do
    transition 'active' => 'inactive', :on => :deactivate
    transition 'inactive' => 'active', :on => :activate
  end

  def self.update_from_admin(aliada_id, activated_recurrences, disabled_recurrences, new_recurrences)
    activated_recurrences.uniq!
    disabled_recurrences.uniq!
    new_recurrences.uniq!

    AliadaWorkingHour.mass_activate(aliada_id, activated_recurrences)

    AliadaWorkingHour.mass_disable(aliada_id, disabled_recurrences)

    AliadaWorkingHour.mass_create(aliada_id, new_recurrences)
  end

  def self.mass_create(aliada_id, new_recurrences)
    new_recurrences.each do |recurrence|
      awh = AliadaWorkingHour.find_or_create_by(aliada_id: aliada_id, weekday: recurrence[:weekday], hour: recurrence[:hour], periodicity: 7, total_hours: 1, user_id: nil)
      # fill 30 days of schedules
      awh.create_schedules_until_horizon        
    end
  end

  def self.mass_activate(aliada_id, activated_recurrences)
    activated_recurrences.each do |recurrence|
      awh = AliadaWorkingHour.find_by(aliada_id: aliada_id, hour: recurrence[:hour], weekday: recurrence[:weekday])
      awh.activate
      awh.save!
      # mark future schedules of that weekday and hour as available
      schedules = awh.create_schedules_until_horizon
      schedules.select { |s| s.busy? }.map(&:enable)
    end
  end

  def self.mass_disable(aliada_id, disabled_recurrences)
    disabled_recurrences.each do |recurrence|
      awh = AliadaWorkingHour.find_by(aliada_id: aliada_id, hour: recurrence[:hour], weekday: recurrence[:weekday])
      awh.deactivate
      awh.save!
      # delete future schedules
      awh.schedules.in_the_future.busy_candidate.destroy_all
    end
  end

  def create_schedules_until_horizon

    starting_datetime = next_recurrence_with_hour_now_in_utc

    recurrence_days = wdays_until_horizon(self.wday, starting_from: starting_datetime)

    schedules = []
    recurrence_days.times do |i|
      schedule = Schedule.find_or_initialize_by(aliada_id: self.aliada_id, datetime: starting_datetime)

      if schedule.new_record? && self.aliada_id
        schedule.aliada_working_hour_id = self.id
        schedule.save!
      else
        schedule.aliada_working_hour_id = self.id
      end
      schedules.push(schedule)

      starting_datetime += self.periodicity.days
    end

    schedules
  end

  rails_admin do
    label_plural 'Horas de trabajo disponibles'
    parent Aliada
    navigation_icon 'icon-time'
    visible false
  end
end

