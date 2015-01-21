class Extra < ActiveRecord::Base
  has_many :extra_services
  has_many :services, through: :extra_services
end
