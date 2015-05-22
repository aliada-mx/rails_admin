class ServiceUnassignment < ActiveRecord::Base
  belongs_to :aliada
  belongs_to :service

  rails_admin do
    visible false 
  end
end
