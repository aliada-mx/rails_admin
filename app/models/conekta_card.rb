class ConektaCard < ActiveRecord::Base
  def create_customer(user, temporary_token)
    customer = Conekta::Customer.create({
      name: user.name,
      email: user.email,
      phone: user.phone,
      cards: [temporary_token] 
    })
    update_from_customer!(customer)
  end

  def update_from_customer!(customer)
    customer_hash = eval(customer.inspect)
    
    card_attributes = customer_hash['cards'].first
    card_attributes = card_attributes.rename_keys({'id' => 'token'})
    card_attributes.except!('created_at', 'object')

    self.update_attributes(card_attributes)
    self
  end

  def charge!(product)
    Conekta::Charge.create({
      amount: product.price_for_conekta,
      currency: 'MXN',
      description: product.description,
      reference_id: product.id,
      card: self.token
    })
  end

  def payment_possible?(service)
    preauthorized?
  end

  def ensure_first_payment!(user, payment_method_options)
    temporary_token = payment_method_options[:conekta_temporary_token]
    create_customer(user, temporary_token)
    preauthorize!(user)
  end

  def preauthorize!(user)
    preauthorization = OpenStruct.new({price_for_conekta: 300,
                                       description: "Pre-autorización de tarjeta #{id}",
                                       reference_id: self.id})
    conekta_charge = charge!(preauthorization)
    payment = Payment.create_from_conekta_charge(conekta_charge,user,self)
    payment.pay!

    self.preauthorized = true
    self.save!
  end

  rails_admin do
    label_plural 'tarjetas de Conekta'
    parent PaymentMethod
    navigation_icon 'icon-chevron-right'
  end
end
