FactoryGirl.define do
  factory :code, class: Code do
    amount 100.0
    association :user, factory: :user
    association :code_type, factory: :code_type
  end
end
