FactoryGirl.define do
  factory :user, class: User do
    role 'user'
    sequence(:email){ |n| "user-#{n}@aliada.mx" }
    password '12345678'
  end

  factory :aliada, parent: :user do
    role 'aliada'
  end
end
