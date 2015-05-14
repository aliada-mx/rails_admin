# -*- encoding : utf-8 -*-
class ConektaCard < PaymentProvider

  def self.create_for_user!(user, temporary_token, object)
    ActiveRecord::Base.transaction requires_new: true do
      conekta_customer = Conekta::Customer.find(user.conekta_customer_id)

      api_card = conekta_customer.create_card(:token => temporary_token)

      conekta_card = ConektaCard.create!
      conekta_card.update_from_api_card(eval(api_card.inspect))
      conekta_card.preauthorize!(user, object)

      user.create_payment_provider_choice(conekta_card).provider
    end
  end

  def friendly_name
    "Tarjeta #{brand} con terminación #{last4}"
  end

  def placeholder_for_form
    self.exp_year = "20#{ exp_year }" if exp_year.present?

    self.last4 = "XXXX XXXX XXXX #{ last4 }" if last4.present?

    self
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

  def charge!(product, user, object)
    begin
      @conekta_charge = charge_in_conekta!(product, user)
     
      payment = Payment.create_from_conekta_charge(@conekta_charge,user,self,object)
      payment.pay!
      
      payment
    rescue Conekta::Error, Conekta::ProcessingError => exception
      object.create_charge_failed_ticket(user, product.amount, exception)
      
      raise exception
    end
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



  def payment_possible?
    preauthorized?
  end

  def ensure_first_payment!(user, payment_method_options, service)
    temporary_token = payment_method_options[:conekta_temporary_token]
    create_customer(user, temporary_token)
    preauthorize!(user, service)
    refund
  end

  def preauthorize!(user, object)
    preauthorization = OpenStruct.new({amount: 3,
                                       description: "Pre-autorización de tarjeta #{id}",
                                       id: self.id})
    charge!(preauthorization, user, object)

    self.preauthorized = true
    self.save!
    @conekta_charge
  end

  def refund
    @conekta_charge.refund()
  end

  rails_admin do
    label_plural 'tarjetas de Conekta'
    parent PaymentMethod
    navigation_icon 'icon-chevron-right'

    configure :created_at do
      sortable true
    end


    list do
      sort_by :created_at

    end
  end
end
