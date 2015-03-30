FactoryGirl.define do
  factory :user, class: User do
    role 'client'
    sequence(:email){ |n| "user-#{n}@aliada.mx" }
    phone '123456'
    first_name 'Test'
    last_name 'User'
    password '12345678'
    
  end

  factory :admin, parent: :user do
    role 'admin'
  end
end
