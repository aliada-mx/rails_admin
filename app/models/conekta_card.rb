# -*- coding: utf-8 -*-
class ConektaCard < ActiveRecord::Base
  def self.create_for_user!(user, temporary_token, service)
    conekta_customer = Conekta::Customer.find(user.conekta_customer_id)

    api_card = conekta_customer.create_card(:token => temporary_token)

    conekta_card = ConektaCard.create!
    conekta_card.update_from_api_card(eval(api_card.inspect))
    conekta_card.preauthorize!(user, service)

    user.create_payment_provider_choice(conekta_card).provider
  end

  def friendly_name
    "Tarjeta #{brand} con terminación #{last4}"
  end

  def placeholder_for_form
    values = {}

    values.merge!({ exp_month: exp_month }) if exp_month.present?

    values.merge!({ exp_year: "20#{ exp_year }" }) if exp_year.present?

    values.merge!({ name: name }) if name.present?

    values.merge!({ last_4: "XXXX XXXX XXXX #{ last4 }" }) if last4.present?

    OpenStruct.new(values)
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

  def charge_in_conekta!(product, user)
    conekta_charge = Conekta::Charge.create({
      amount: (product.amount * 100).floor,
      currency: 'MXN',
      description: product.description,
      reference_id: product.id,
      card: self.customer_id || self.token,
      details: {
        name: user.name,
        email: user.email,
        phone: user.phone,
      }
    })

    conekta_charge
  end

  def charge!(product, user, service)
    begin
      conekta_charge = charge_in_conekta!(product, user)
     
      payment = Payment.create_from_conekta_charge(conekta_charge,user,self)
      payment.pay!
      
      payment
    rescue Conekta::Error => exception
      Raygun.track_exception(exception)

      service.create_charge_failed_ticket(user, product.price, exception)
      nil
    end
  end

  def payment_possible?(service)
    preauthorized?
  end

  def ensure_first_payment!(user, payment_method_options, service)
    temporary_token = payment_method_options[:conekta_temporary_token]
    create_customer(user, temporary_token)
    preauthorize!(user, service)
  end

  def preauthorize!(user, service)
    preauthorization = OpenStruct.new({amount: 3,
                                       description: "Pre-autorización de tarjeta #{id}",
                                       id: self.id})
    charge!(preauthorization, user, service)

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