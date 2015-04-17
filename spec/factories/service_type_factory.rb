# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :service_type, class: ServiceType do
    name 'recurrent'
    periodicity 7
    price_per_hour 65
  end
end
