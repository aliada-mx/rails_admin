FactoryGirl.define do
  factory :schedule, class: Schedule do
    status 'available'
    datetime Time.now    
    association :aliada, factory: :aliada

    transient do
      zone { create(:zone) }
    end

    after :build do |schedule, evaluator|
      schedule.zones << evaluator.zone
    end

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