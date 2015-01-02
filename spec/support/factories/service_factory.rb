FactoryGirl.define do
  factory :service, class: Service do
    association :address, factory: :address
  end
end
