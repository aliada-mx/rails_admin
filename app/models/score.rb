# -*- encoding : utf-8 -*-
class Score < ActiveRecord::Base
  belongs_to :user
  belongs_to :service
  belongs_to :aliada

  rails_admin do
    label_plural 'calificaciones'
    parent Aliada
    navigation_icon 'icon-certificate'

    list do
      field :user
      field :value
      field :aliada
      field :service
    end
  end
end
