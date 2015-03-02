class ServiceType < ActiveRecord::Base
  NAMES = [
    ['recurrent','Recurrente'],
    ['one-time','Una sola vez'],
  ]

  validates :name, inclusion: {in: NAMES.map{ |pairs| pairs[0] } }

  def recurrent?
    name == 'recurrent'
  end

  def one_timer?
    name == 'one-time'
  end

  rails_admin do
    label_plural 'tipos de servicio'
    label_plural 'tipos de servicios'
    parent Service
    navigation_icon 'icon-barcode'
  end
end