class Address < ActiveRecord::Base
  include Presenters::AddressPresenter
  attr_accessor :postal_code_number

  belongs_to :user, inverse_of: :addresses
  belongs_to :postal_code
  has_many :services

  validate :postal_code_or_number

  before_validation :ensure_postal_code!
  
  def full_address
    return "#{self.street} #{self.number} int. #{self.interior_number}, Col. #{self.colony}, #{self.city}"
  end

  def map_missing?
    latitude.zero? || longitude.zero?
  end

  def postal_code_or_number
    message = I18n.t('address.validations.postal_code_failed')

    valid = self.postal_code_id.present?

    unless valid
      valid = self.postal_code_number.present? ? PostalCode.find_by_number(self.postal_code_number).present? : false
    end

    errors.add(:postal_code, message) if !valid
  end

  # An address might be instantiated with a postal code code and not a PostalCode object
  def ensure_postal_code!
    if postal_code_number.present?
      new_postal_code = PostalCode.find_by(number: postal_code_number)
      if new_postal_code
        self.postal_code = new_postal_code 
      end
    end
  end

  rails_admin do
    parent User
    navigation_icon 'icon-map-marker'
    label_plural 'direcciones'

    configure :latitude do
      visible false
    end

    configure :longitude do
      visible false
    end
  end
end
