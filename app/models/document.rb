class Document < ActiveRecord::Base
  belongs_to :user

  rails_admin do
    label_plural 'archivos'
    parent Aliada
    navigation_icon 'icon-briefcase'
  end
end
