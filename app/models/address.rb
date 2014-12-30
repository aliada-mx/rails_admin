class Address < ActiveRecord::Base
  belongs_to :user
  belongs_to :postal_code
end
