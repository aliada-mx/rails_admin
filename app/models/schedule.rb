class Schedule < ActiveRecord::Base
  belongs_to :zone
  belongs_to :user
  belongs_to :service
end
