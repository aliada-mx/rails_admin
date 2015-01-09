FactoryGirl.define do
  factory :zone, class: Zone do
    sequence(:name){ |n| "Zone-#{n}" }
  end
end
