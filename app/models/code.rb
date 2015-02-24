class Code < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_type

  rails_admin do
    visible false
  end
end
