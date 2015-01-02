FactoryGirl.define do
  factory :schedule, class: Schedule do
    status 'available'
    datetime Time.now    
    association :aliada, factory: :aliada
    association :zone, factory: :zone
    association :service, factory: :service
  end
end
