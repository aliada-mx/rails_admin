FactoryGirl.define do
  factory :payment_method, class: PaymentMethod do
    name 'Conekta credit card'
    payment_provider_type 'ConektaCard'
  end
end
