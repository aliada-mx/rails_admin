class ExtraService < ActiveRecord::Base
  belongs_to :service
  belongs_to :extra

  rails_admin do
    visible false
  end
end
