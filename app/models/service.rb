class Service < ActiveRecord::Base
  belongs_to :zone
  belongs_to :address
  belongs_to :user
  belongs_to :service_type
  belongs_to :recurrence
end
