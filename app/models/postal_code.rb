class PostalCode < ActiveRecord::Base
  has_many :postal_code_zones
  has_many :zones, through: :postal_code_zones

  rails_admin do
    label_plural 'códigos postales'
    navigation_label 'Contenidos'
    navigation_icon 'icon-envelope'
    weight -3
  end
end
