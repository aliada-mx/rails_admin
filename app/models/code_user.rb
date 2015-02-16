class CodeUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :code

  rails_admin do
    visible false
  end
end
