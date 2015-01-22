class Address < ActiveRecord::Base
  belongs_to :user, inverse_of: :addresses
  belongs_to :postal_code
  has_many :services
end
