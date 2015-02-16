class PaymentProviderChoice < ActiveRecord::Base
  belongs_to :payment_provider, polymorphic: true
  belongs_to :user, inverse_of: :payment_provider_choices

  scope :default, -> { where(default: true).first }

  delegate :name, to: :payment_provider
  delegate :payment_possible?, to: :payment_provider
  delegate :ensure_first_payment!, to: :payment_provider
  delegate :charge!, to: :payment_provider

  # We limit the polymorphism to valid payment providers classes
  validates_uniqueness_of :default, scope: :user_id, message: 'Ya hay un método de pago elegido por defecto.'

  def provider
    payment_provider
  end

  rails_admin do
    visible false
  end
end
