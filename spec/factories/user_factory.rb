FactoryGirl.define do
  factory :user, class: User do
    role 'user'
    sequence(:email){ |n| "user-#{n}@aliada.mx" }
  end

  factory :aliada, parent: :user do
    role 'aliada'
  end
end
