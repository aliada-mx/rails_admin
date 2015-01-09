FactoryGirl.define do
  factory :recurrence, class: Recurrence do
    starting_datetime Time.zone.now
    association :user, factory: :user
    periodicity 7
  end
end
