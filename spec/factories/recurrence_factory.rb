FactoryGirl.define do
  factory :recurrence, class: Recurrence do
    weekday 'monday'
    hour 7
    association :user, factory: :user
    periodicity 7
  end
end
