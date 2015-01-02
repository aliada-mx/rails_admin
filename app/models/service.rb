class Service < ActiveRecord::Base
  belongs_to :zone
  belongs_to :address
  belongs_to :user
  belongs_to :service_type
  belongs_to :recurrence
  has_many :schedules

  validate :schedule_possible

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :user

  def schedule_possible
  end
end
