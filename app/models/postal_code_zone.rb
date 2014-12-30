class PostalCodeZone < ActiveRecord::Base
  belongs_to :postal_code
  belongs_to :zone
end
