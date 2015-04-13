# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :address, class: Address do
    association :postal_code, factory: :postal_code
  end
end
