# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :recurrence, class: Recurrence do
    weekday 'monday'
    hour 7
    periodicity 7
    association :aliada, factory: :aliada
    estimated_hours 3.0
    association :address, factory: :address
    association :user, factory: :user
  end
end
