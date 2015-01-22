FactoryGirl.define do
  factory :aliada, class: Aliada do
    role 'aliada'
    sequence(:email){ |n| "aliada-#{n}@aliada.mx" }
    password '12345678'
  end
end
