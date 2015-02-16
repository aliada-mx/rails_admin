class Score < ActiveRecord::Base
  belongs_to :user

  rails_admin do
    label_plural 'calificaciones'
    parent Aliada
    navigation_icon 'icon-certificate'
  end
end
