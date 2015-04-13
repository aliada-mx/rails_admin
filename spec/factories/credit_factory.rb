# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :credit, class: Credit do
    association :code, factory: :code
    association :user, factory: :user
    association :redeemer, factory: :user
  end
end
