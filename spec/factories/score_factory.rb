# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :score, class: Score do
    association :user, factory: :user
    association :aliada, factory: :aliada
    association :service, factory: :service
    value 4
  end
end
