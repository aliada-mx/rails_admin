# -*- encoding : utf-8 -*-
class PaymentProviderChoice < ActiveRecord::Base
  belongs_to :payment_provider, polymorphic: true
  belongs_to :user, inverse_of: :payment_provider_choices

  scope :default, -> { where(default: true).first }
  scope :ordered_by_created_at, -> { order(:created_at) }

  delegate :payment_possible?, to: :payment_provider
  delegate :ensure_first_payment!, to: :payment_provider
  delegate :charge!, to: :payment_provider

  # We limit the polymorphism to valid payment providers classes
  validates_uniqueness_of :default, scope: :user_id, message: 'Ya hay un método de pago elegido por defecto.', conditions: -> { where(default: true) }

  def name
    "#{ payment_provider.friendly_name } #{default ? '[ACTIVA]':''}"
  end

  def provider
    payment_provider
  end
  
  rails_admin do
    label_plural 'Formas de pago elegidas'
    parent PaymentMethod
    navigation_icon 'icon-hand-right'

    list do
      field :name do
        virtual?
      end
      field :user
      field :default
    end
  end
end
