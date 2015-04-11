# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :service_type, class: ServiceType do
    name 'recurrent'
    periodicity 7
    price_per_hour 65
  end

  factory :one_time_from_recurrent, parent: :service_type do
    name 'one-time-from-recurrent'
  end
end
