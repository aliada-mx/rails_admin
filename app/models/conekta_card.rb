# -*- coding: utf-8 -*-
class ConektaCard < ActiveRecord::Base
  def self.create_for_user!(user, temporary_token)
    conekta_customer = Conekta::Customer.find(user.conekta_customer_id)

    api_card = conekta_customer.create_card(:token => temporary_token)

    conekta_card = ConektaCard.create!
    conekta_card.update_from_api_card(eval(api_card.inspect))
    conekta_card.preauthorize!(user)

    user.create_payment_provider_choice(conekta_card).provider
  end

  def create_customer(user, temporary_token)
    customer = Conekta::Customer.create({
      name: user.name,
      email: user.email,
      phone: user.phone,
      cards: [temporary_token] 
    })

    user.update_attribute(:conekta_customer_id, customer.id)
    update_from_customer!(customer)
    customer
  end

  def update_from_api_card(card_attributes)
    card_attributes = card_attributes.rename_keys({'id' => 'token'})
    card_attributes.except!('created_at', 'object', 'address')

    self.update_attributes(card_attributes)
    self
  end

  def update_from_customer!(customer)
    customer_hash = eval(customer.inspect)
    
    card_attributes = customer_hash['cards'].first
    update_from_api_card(card_attributes)
  end

  def charge!(product, user)
    conekta_charge = Conekta::Charge.create({
      amount: (product.price * 100).floor,
      currency: 'MXN',
      description: product.description,
      reference_id: product.id,
      card: self.token
    })
   
    payment = Payment.create_from_conekta_charge(conekta_charge,user,self)
    payment.pay!
    
    return conekta_charge
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
    preauthorization = OpenStruct.new({price: 300,
                                       description: "Pre-autorización de tarjeta #{id}",
                                       id: self.id})
    charge!(preauthorization, user)

    

    self.preauthorized = true
    self.save!
    self
  end

  rails_admin do
    label_plural 'tarjetas de Conekta'
    parent PaymentMethod
    navigation_icon 'icon-chevron-right'
  end
end
