# -*- encoding : utf-8 -*-
class ServiceType < ActiveRecord::Base
  NAMES = [
    ['Recurrente','recurrent'],
    ['Una sola vez', 'one-time'],
    ['Una sola vez derivado de una recurrencia', 'one-time-from-recurrent'],
  ]

  scope :ordered, -> { order(:position) }
  scope :visible, -> { where(hidden: false) }

  default_scope { order(:created_at) }

  validates :name, inclusion: {in: NAMES.map{ |pairs| pairs[1] } }

  def name_enum
    NAMES
  end

  def self.recurrent
    ServiceType.where(name: 'recurrent').first 
  end

  def self.one_time
    ServiceType.where(name: 'one-time').first 
  end

  def self.one_time_from_recurrent
    ServiceType.where(name: 'one-time-from-recurrent').first 
  end

  def recurrent?
    name == 'recurrent'
  end

  def one_timer?
    name == 'one-time' || name == 'one-time-from-recurrent'
  end
 
  def one_timer_from_recurrent?
    name == 'one-time-from-recurrent'
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

    list do
      include_fields :name, :price_per_hour, :periodicity
    end
  end
end
