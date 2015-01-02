class PostalCode < ActiveRecord::Base
  has_many :postal_code_zones
  has_many :zones, through: :postal_code_zones
end
