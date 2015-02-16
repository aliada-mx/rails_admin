class Address < ActiveRecord::Base
  include Presenters::AddressPresenter

  belongs_to :user, inverse_of: :addresses
  belongs_to :postal_code
  has_many :services

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
