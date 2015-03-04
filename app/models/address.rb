class Address < ActiveRecord::Base
  include Presenters::AddressPresenter
  attr_accessor :postal_code_number

  belongs_to :user, inverse_of: :addresses
  belongs_to :postal_code
  has_many :services

  validates_presence_of :postal_code

  before_validation :ensure_postal_code!

  # An address might be instantiated with a postal code code and not a PostalCode object
  def ensure_postal_code!
    return if postal_code_id.present?

    if postal_code_number.present?
      self.postal_code = PostalCode.find_by!(code: postal_code_number)
      self.save!
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
