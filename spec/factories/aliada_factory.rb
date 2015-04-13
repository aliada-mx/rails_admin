# -*- encoding : utf-8 -*-
FactoryGirl.define do
  factory :aliada, class: Aliada do
    role 'aliada'
    sequence(:email){ |n| "aliada-#{n}@aliada.mx" }
    password '12345678'

    trait :zoned do
      transient do
        zone { create(:zone) }
      end

      after :create do |aliada, evaluator|
        zones << create(aliada: aliada)
      end
    end
  end
end
