class ServiceType < ActiveRecord::Base
  NAMES = [
    ['recurrent','Recurrente'],
    ['one-time','Una sola vez'],
  ]

  validates :name, inclusion: {in: NAMES.map{ |pairs| pairs[0] } }

  def self.recurrent
    ServiceType.where(name: 'recurrent').first 
  end

  def self.one_time
    ServiceType.where(name: 'one-time').first 
  end

  def recurrent?
    name == 'recurrent'
  end

  def one_timer?
    name == 'one-time'
  end

  def benefits_list
    benefits.present? ? benefits.split(',') : []
  end

  rails_admin do
    label_plural 'tipos de servicios'
    parent Service
    navigation_icon 'icon-barcode'

    configure :benefits do
      help 'Frases separadas por comas'
    end
  end
end
