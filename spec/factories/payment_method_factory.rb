FactoryGirl.define do
  factory :payment_method, class: PaymentMethod do
    name 'Tarjeta'
    payment_provider_type 'ConektaCard'
  end
end
