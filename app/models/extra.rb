class Extra < ActiveRecord::Base
  has_many :extra_services
  has_many :services, through: :extra_services

  rails_admin do
    label_plural 'extras'
    navigation_label 'Contenidos'
    navigation_icon 'icon-tasks'

    configure :hours do
      help 'Horas que toma realizar el servicio, decimales aceptados'
    end
  end
end
