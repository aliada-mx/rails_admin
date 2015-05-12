# -*- encoding : utf-8 -*-
class PaymentMethod < ActiveRecord::Base
  # We limit the polymorphism to valid payment providers classes
  validates :payment_provider_type, inclusion: {in: Setting.payment_providers.map{ |pairs| pairs[1] } }

  scope :manual, -> { where("payment_provider_type IN (?)", ['PaypalExpress']) }
  scope :automatic, -> {  where("payment_provider_type IN (?)", ['ConektaCard']) }

  def provider_class
    payment_provider_type.constantize
  end

  rails_admin do
    label_plural 'métodos de pago'
    navigation_label 'Contenidos'
    navigation_icon 'icon-tag'
  end
end
