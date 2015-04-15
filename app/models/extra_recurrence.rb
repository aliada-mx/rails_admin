# -*- encoding : utf-8 -*-
class ExtraRecurrence < ActiveRecord::Base
  belongs_to :recurrence
  belongs_to :extra

  rails_admin do
    visible false
  end
end
