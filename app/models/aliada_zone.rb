class AliadaZone < ActiveRecord::Base
  belongs_to :aliada
  belongs_to :zone

  rails_admin do
    visible false
  end
end
