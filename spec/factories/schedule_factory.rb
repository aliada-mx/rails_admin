FactoryGirl.define do
  factory :schedule, class: Schedule do
    status 'available'
    datetime Time.now    
    association :aliada, factory: :aliada
    association :zone, factory: :zone

    trait :with_service do
      transient do
        service { create(:service) }
      end
      
      after :create do |schedule, evaluator|
        schedule.service << evaluator.service
      end
    end
  end
end
