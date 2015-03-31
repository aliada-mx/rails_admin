class Zone < ActiveRecord::Base
  has_many :aliada_zones
  has_many :aliadas, through: :aliada_zones
  has_and_belongs_to_many :schedules

  has_many :postal_codes

  def self.find_by_postal_code(postal_code)
    Zone.joins(:postal_codes).where('postal_codes.id = ?', postal_code.id).try(:first)
  end

  def self.find_by_postal_code_number(number)
    Zone.joins(:postal_codes).where('postal_codes.number = ?', number).try(:first)
  end

  rails_admin do
    label_plural 'zonas'
    navigation_label 'Contenidos'
    navigation_icon 'icon-globe'
    weight -4

    edit do
      field :name
      field :postal_codes
    end
  end
end
