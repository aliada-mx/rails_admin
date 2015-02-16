class PostalCodeZone < ActiveRecord::Base
  belongs_to :postal_code
  belongs_to :zone

  rails_admin do
    visible false
  end
end
