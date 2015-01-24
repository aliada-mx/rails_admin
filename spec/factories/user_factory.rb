FactoryGirl.define do
  factory :user, class: User do
    role 'client'
    sequence(:email){ |n| "user-#{n}@aliada.mx" }
    password '12345678'
  end
end
