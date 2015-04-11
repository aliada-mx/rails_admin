# -*- encoding : utf-8 -*-
class Credit < ActiveRecord::Base
  belongs_to :user
  belongs_to :code
  belongs_to :redeemer, :foreign_key => "redeemer_id", :class_name => "User"

  rails_admin do
    visible false
  end
end
