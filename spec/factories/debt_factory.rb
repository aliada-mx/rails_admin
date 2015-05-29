# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :debt, class: Debt do
    association :service, factory: :service
    association :user, factory: :user
    category 'service'
    amount 0
  end
end
