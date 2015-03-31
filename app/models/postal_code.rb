class PostalCode < ActiveRecord::Base
  belongs_to :zone

  validates_presence_of :zone_id

  rails_admin do
    label_plural 'códigos postales'
    navigation_label 'Contenidos'
    navigation_icon 'icon-envelope'
    weight -3

    list do
      field :number
      field :name
      field :zone
    end
  end
end
