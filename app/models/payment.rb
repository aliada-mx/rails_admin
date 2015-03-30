class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :payment_provider, polymorphic: true

  # We limit the polymorphism to valid payment providers classes
  validates :payment_provider_type, inclusion: {in: Setting.payment_providers.map{ |pairs| pairs[1] } }
  validates_presence_of :user

  # State machine
  state_machine :status, :initial => 'unpaid' do
    transition 'unpaid' => 'paid', :on => :pay
  end

  def self.create_from_conekta_charge(charge, user, payment_provider)
    charge_hash = eval(charge.inspect)
    # Save the whole conekta response for future reference

    Payment.create!(amount: charge_hash['amount'] / 100.0, 
                    user: user,
                    payment_provider: payment_provider,
                    api_raw_response: charge_hash.to_json)
  end

  def self.create_from_credit_payment(amount, user)
    Payment.create!(amount: amount, 
                    user: user,
                    payment_provider_type: 'User',
                    payment_provider_id: user.id)
  end

  def provider
    payment_provider
  end

  rails_admin do
    parent Service
    label_plural 'cobros'
    navigation_label 'Operación'
    navigation_icon 'icon-shopping-cart'

    configure :api_raw_response do
      visible false
    end

    configure :status do
      read_only true
    end

    list do
      include_fields :user, :amount, :status
    end
  end
end
