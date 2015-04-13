# -*- encoding : utf-8 -*-
class CodeType < ActiveRecord::Base
  NAMES = [
    ['personal', 'Personal'],
    ['campaign', 'Campaña']
  ]
  
  validates :name, inclusion: {in: NAMES.map{ |pairs| pairs[0] } }

  rails_admin do
    visible false
  end
end
