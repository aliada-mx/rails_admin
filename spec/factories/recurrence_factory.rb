FactoryGirl.define do
  factory :recurrence, class: Recurrence do
    weekday 'monday'
    hour 7
    periodicity 7
    association :aliada, factory: :aliada
    association :zone, factory: :zone
    total_hours 3
  end
end
