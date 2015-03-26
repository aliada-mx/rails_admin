FactoryGirl.define do
  factory :recurrence, class: Recurrence do
    weekday 'monday'
    hour 7
    periodicity 7
    total_hours 3
    owner 'user'
    association :aliada, factory: :aliada
    association :user, factory: :user
  end
end
