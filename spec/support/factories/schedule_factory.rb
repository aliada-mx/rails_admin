FactoryGirl.define do
  factory :schedule, class: Schedule do
    status 'available'
    datetime Time.now    
    association :user, factory: :user
    association :zone, factory: :zone
    association :service, factory: :service
  end
end
